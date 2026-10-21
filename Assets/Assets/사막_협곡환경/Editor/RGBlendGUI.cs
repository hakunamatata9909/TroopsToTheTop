#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace RGTools 
{
    public class RGBlendStylizedGUI : ShaderGUI
    {
        // Variables to remember foldout states
        bool showDebug = true; 
        bool showBase = true;
        bool showR = true;
        bool showG = true;
        bool showDetail = true;
        bool showGradient = true; 
        bool showGlobal = false;
        bool showStyle = true; 

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            GUIStyle foldoutStyle = new GUIStyle(EditorStyles.foldout);
            foldoutStyle.fontStyle = FontStyle.Bold;
            foldoutStyle.fontSize = 12;

            GUIStyle debugStyle = new GUIStyle(EditorStyles.foldout);
            debugStyle.fontStyle = FontStyle.Bold;
            debugStyle.normal.textColor = new Color(1f, 0.5f, 0.5f);

            // --- DEBUG ---
            EditorGUILayout.Space();
            showDebug = EditorGUILayout.Foldout(showDebug, "DEBUG TOOLS", true, debugStyle);
            if (showDebug)
            {
                EditorGUI.indentLevel++;
                MaterialProperty debugProp = FindProperty("_Debug", properties, false);
                if (debugProp != null)
                {
                    materialEditor.ShaderProperty(debugProp, "Visualization Mode");
                    int val = (int)debugProp.floatValue;
                    if (val == 7) EditorGUILayout.HelpBox("Preview: Shows Gradient (Blue = Bottom, Red = Top)", MessageType.Info);
                }
                EditorGUI.indentLevel--;
            }

            // --- BASE ---
            EditorGUILayout.Space();
            showBase = EditorGUILayout.Foldout(showBase, "Base Layer", true, foldoutStyle);
            if (showBase)
            {
                EditorGUI.indentLevel++;
                FindProp("_BaseUseWorldUV", properties, materialEditor);
                EditorGUILayout.Space(5);
                FindProp("_BaseMap", properties, materialEditor);
                FindProp("_BaseColor", properties, materialEditor);
                FindProp("_BaseNormal", properties, materialEditor);
                FindProp("_BaseNormalScale", properties, materialEditor);
                FindProp("_BaseMask", properties, materialEditor);
                FindProp("_BaseSmoothness", properties, materialEditor);
                MaterialProperty worldUV = FindProperty("_BaseUseWorldUV", properties, false);
                if (worldUV != null && worldUV.floatValue < 0.5f) FindProp("_BaseTiling", properties, materialEditor);
                EditorGUI.indentLevel--;
            }

            // --- LAYER R ---
            EditorGUILayout.Space();
            showR = EditorGUILayout.Foldout(showR, "Layer R", true, foldoutStyle);
            if (showR)
            {
                EditorGUI.indentLevel++;
                MaterialProperty enableR = FindProperty("_EnableLayerR", properties, false);
                if (enableR != null)
                {
                    materialEditor.ShaderProperty(enableR, enableR.displayName);
                    if (enableR.floatValue > 0.5f) 
                    {
                        FindProp("_RUseWorldUV", properties, materialEditor);
                        FindProp("_RMap", properties, materialEditor);
                        FindProp("_RColor", properties, materialEditor);
                        FindProp("_RNormal", properties, materialEditor);
                        FindProp("_RNormalScale", properties, materialEditor);
                        FindProp("_RMask", properties, materialEditor);
                        FindProp("_RSmoothness", properties, materialEditor);
                        MaterialProperty worldUV_R = FindProperty("_RUseWorldUV", properties, false);
                        if (worldUV_R != null && worldUV_R.floatValue < 0.5f) FindProp("_RTiling", properties, materialEditor);
                        
                        EditorGUILayout.LabelField("Blend", EditorStyles.boldLabel);
                        FindProp("_BlendBiasR", properties, materialEditor);
                        FindProp("_BlendContrastR", properties, materialEditor);
                    }
                }
                EditorGUI.indentLevel--;
            }

            // --- LAYER G ---
            EditorGUILayout.Space();
            showG = EditorGUILayout.Foldout(showG, "Layer G", true, foldoutStyle);
            if (showG)
            {
                EditorGUI.indentLevel++;
                MaterialProperty enableG = FindProperty("_EnableLayerG", properties, false);
                if (enableG != null)
                {
                    materialEditor.ShaderProperty(enableG, enableG.displayName);
                    if (enableG.floatValue > 0.5f)
                    {
                        FindProp("_GUseWorldUV", properties, materialEditor);
                        FindProp("_GMap", properties, materialEditor);
                        FindProp("_GColor", properties, materialEditor);
                        FindProp("_GNormal", properties, materialEditor);
                        FindProp("_GNormalScale", properties, materialEditor);
                        FindProp("_GMask", properties, materialEditor);
                        FindProp("_GSmoothness", properties, materialEditor);
                        MaterialProperty worldUV_G = FindProperty("_GUseWorldUV", properties, false);
                        if (worldUV_G != null && worldUV_G.floatValue < 0.5f) FindProp("_GTiling", properties, materialEditor);
                        
                        EditorGUILayout.LabelField("Blend", EditorStyles.boldLabel);
                        FindProp("_BlendBiasG", properties, materialEditor);
                        FindProp("_BlendContrastG", properties, materialEditor);
                    }
                }
                EditorGUI.indentLevel--;
            }

            // --- DETAIL ---
            EditorGUILayout.Space();
            showDetail = EditorGUILayout.Foldout(showDetail, "Detail Layer", true, foldoutStyle);
            if (showDetail)
            {
                EditorGUI.indentLevel++;
                MaterialProperty enableDetail = FindProperty("_EnableDetailLayer", properties, false);
                if (enableDetail != null)
                {
                    materialEditor.ShaderProperty(enableDetail, enableDetail.displayName);
                    if (enableDetail.floatValue > 0.5f)
                    {
                        FindProp("_DetailTarget", properties, materialEditor);
                        FindProp("_DetailMap", properties, materialEditor);
                        FindProp("_DetailColor", properties, materialEditor);
                        FindProp("_DetailTiling", properties, materialEditor);
                        FindProp("_DetailStrength", properties, materialEditor);
                    }
                }
                EditorGUI.indentLevel--;
            }

            // --- VERTICAL GRADIENT (NEW) ---
            EditorGUILayout.Space();
            showGradient = EditorGUILayout.Foldout(showGradient, "Vertical Gradient", true, foldoutStyle);
            if (showGradient)
            {
                EditorGUI.indentLevel++;
                MaterialProperty enableGrad = FindProperty("_EnableGradient", properties, false);
                if (enableGrad != null)
                {
                    materialEditor.ShaderProperty(enableGrad, enableGrad.displayName);
                    if (enableGrad.floatValue > 0.5f)
                    {
                        EditorGUILayout.Space();
                        FindProp("_GradientSpace", properties, materialEditor);
                        EditorGUILayout.HelpBox("Object Space: Moves with object. World Space: Static like fog.", MessageType.None);
                        
                        EditorGUILayout.Space();
                        EditorGUILayout.LabelField("Noise Mask", EditorStyles.boldLabel);
                        FindProp("_GradientNoiseMap", properties, materialEditor);
                        FindProp("_GradientNoiseScale", properties, materialEditor);
                        FindProp("_GradientNoiseStrength", properties, materialEditor);

                        EditorGUILayout.Space();
                        EditorGUILayout.LabelField("Bottom Gradient (Darken/Dirt)", EditorStyles.boldLabel);
                        FindProp("_GradientBottomColor", properties, materialEditor);
                        FindProp("_GradientBottomPos", properties, materialEditor);
                        FindProp("_GradientBottomSoftness", properties, materialEditor);
                        FindProp("_GradientBottomIntensity", properties, materialEditor); // <--- NOWE

                        EditorGUILayout.Space();
                        EditorGUILayout.LabelField("Top Gradient (Bleach/Moss)", EditorStyles.boldLabel);
                        FindProp("_GradientTopColor", properties, materialEditor);
                        FindProp("_GradientTopPos", properties, materialEditor);
                        FindProp("_GradientTopSoftness", properties, materialEditor);
                        FindProp("_GradientTopIntensity", properties, materialEditor); // <--- NOWE
                    }
                }
                EditorGUI.indentLevel--;
            }

            // --- STYLIZED ---
            EditorGUILayout.Space();
            showStyle = EditorGUILayout.Foldout(showStyle, "Stylized Options", true, foldoutStyle);
            if (showStyle)
            {
                EditorGUI.indentLevel++;
                MaterialProperty stylizedToggle = FindProperty("_EnableStylized", properties, false);
                if (stylizedToggle != null)
                {
                    materialEditor.ShaderProperty(stylizedToggle, stylizedToggle.displayName);
                    if (stylizedToggle.floatValue > 0.5f)
                    {
                        FindProp("_ShadowFlatness", properties, materialEditor);
                        FindProp("_SkyColor", properties, materialEditor);
                        FindProp("_GroundColor", properties, materialEditor);
                    }
                }
                EditorGUI.indentLevel--;
            }

            // --- GLOBAL ---
            EditorGUILayout.Space();
            showGlobal = EditorGUILayout.Foldout(showGlobal, "Global Settings", true, foldoutStyle);
            if (showGlobal)
            {
                EditorGUI.indentLevel++;
                FindProp("_OcclusionStrength", properties, materialEditor);
                FindProp("_WorldUVScale", properties, materialEditor);
                EditorGUI.indentLevel--;
            }

            // --- STANDARD ---
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Advanced", EditorStyles.boldLabel);
            materialEditor.RenderQueueField();
            materialEditor.EnableInstancingField();
            materialEditor.DoubleSidedGIField();
        }

        void FindProp(string name, MaterialProperty[] props, MaterialEditor editor)
        {
            MaterialProperty prop = FindProperty(name, props, false);
            if (prop != null) editor.ShaderProperty(prop, prop.displayName);
        }
    }
}
#endif