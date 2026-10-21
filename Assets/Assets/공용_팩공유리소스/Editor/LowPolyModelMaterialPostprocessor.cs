using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

// Raw FBX exports contain the author's absolute texture paths. Resolve their atlases
// from the import catalogue after models/textures are sorted into separate folders.
internal sealed class LowPolyModelMaterialPostprocessor : AssetPostprocessor
{
    [Serializable] private sealed class Catalogue { public Model[] models; }
    [Serializable] private sealed class Model { public string model; public Binding[] materials; }
    [Serializable] private sealed class Binding { public string material; public string texture; }
    private static Dictionary<string, Binding[]> models;
    private static DateTime catalogueTime;

    public override int GetPostprocessOrder() => 2000;
    public override uint GetVersion() => 1;

    private void OnPostprocessMaterial(Material material)
    {
        string file = Path.GetFullPath(Path.Combine(Application.dataPath, "../Tools/AssetImport/model-material-bindings.json"));
        DateTime timestamp = File.Exists(file) ? File.GetLastWriteTimeUtc(file) : DateTime.MinValue;
        if (models == null || timestamp != catalogueTime)
        {
            models = new Dictionary<string, Binding[]>(StringComparer.OrdinalIgnoreCase);
            catalogueTime = timestamp;
            if (File.Exists(file))
                foreach (Model model in JsonUtility.FromJson<Catalogue>(File.ReadAllText(file)).models)
                    models[model.model] = model.materials;
        }
        if (!models.TryGetValue(assetPath, out Binding[] bindings)) return;
        foreach (Binding binding in bindings)
        {
            if (!string.Equals(binding.material, material.name, StringComparison.Ordinal)) continue;
            Texture2D atlas = AssetDatabase.LoadAssetAtPath<Texture2D>(binding.texture);
            if (atlas == null) return;
            if (material.HasProperty("_BaseMap"))
            {
                material.SetTexture("_BaseMap", atlas);
                Color tint = material.GetColor("_BaseColor");
                material.SetColor("_BaseColor", new Color(1f, 1f, 1f, tint.a));
            }
            else if (material.HasProperty("_MainTex")) material.SetTexture("_MainTex", atlas);
            return;
        }
    }

    // Some source prefabs override a shared FBX material differently on each renderer.
    // Store only those exceptions; GUIDs preserve them when asset folders are renamed.
    [Serializable] private sealed class RendererCatalogue { public RendererModel[] models; }
    [Serializable] private sealed class RendererModel { public string guid; public RendererBinding[] renderers; }
    [Serializable] private sealed class RendererBinding { public string node; public RendererSlot[] slots; }
    [Serializable] private sealed class RendererSlot { public int slot; public string materialGuid; }
    private static Dictionary<string, RendererBinding[]> rendererModels;
    private static DateTime rendererCatalogueTime;

    private void OnPostprocessModel(GameObject root)
    {
        string file = Path.GetFullPath(Path.Combine(Application.dataPath, "../Tools/AssetImport/model-renderer-material-bindings.json"));
        DateTime timestamp = File.Exists(file) ? File.GetLastWriteTimeUtc(file) : DateTime.MinValue;
        if (rendererModels == null || timestamp != rendererCatalogueTime)
        {
            rendererModels = new Dictionary<string, RendererBinding[]>(StringComparer.OrdinalIgnoreCase);
            rendererCatalogueTime = timestamp;
            if (File.Exists(file))
                foreach (RendererModel model in JsonUtility.FromJson<RendererCatalogue>(File.ReadAllText(file)).models)
                    rendererModels[model.guid] = model.renderers;
        }
        string guid = AssetDatabase.AssetPathToGUID(assetPath);
        if (!rendererModels.TryGetValue(guid, out RendererBinding[] bindings)) return;
        foreach (RendererBinding binding in bindings)
        {
            Transform target = string.IsNullOrEmpty(binding.node) ? root.transform : root.transform.Find(binding.node);
            Renderer renderer = target == null ? null : target.GetComponent<Renderer>();
            if (renderer == null) continue;
            Material[] materials = renderer.sharedMaterials;
            foreach (RendererSlot slot in binding.slots)
            {
                if (slot.slot < 0 || slot.slot >= materials.Length) continue;
                Material material = AssetDatabase.LoadAssetAtPath<Material>(AssetDatabase.GUIDToAssetPath(slot.materialGuid));
                if (material != null) materials[slot.slot] = material;
            }
            renderer.sharedMaterials = materials;
        }
    }
}
