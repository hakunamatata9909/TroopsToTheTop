#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace RGTools
{
    public class FoliageShaderGUI : ShaderGUI
    {
        // Foldout states
        static bool showSurface = true;
        static bool showWind = true;
        static bool showStylized = true;
        static bool showVariation = true;
        static bool showTranslucency = false;
        static bool showGround = false;
        static bool showAdvanced = false;

        // Styles
        GUIStyle foldoutStyle;
        bool stylesInitialized = false;

        void InitStyles()
        {
            if (stylesInitialized) return;
            foldoutStyle = new GUIStyle(EditorStyles.foldout);
            foldoutStyle.fontStyle = FontStyle.Bold;
            foldoutStyle.fontSize = 11;
            stylesInitialized = true;
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            InitStyles();
            Material material = materialEditor.target as Material;

            // --- SURFACE OPTIONS ---
            EditorGUILayout.Space();
            showSurface = EditorGUILayout.Foldout(showSurface, "Surface & Cutout", true, foldoutStyle);
            if (showSurface)
            {
                MaterialProperty colorTex = FindProperty("_ColorTexture", properties, false);
                MaterialProperty tint = FindProperty("_Tint", properties, false);

                if (colorTex != null)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Albedo Texture"), colorTex);
                }

                if (tint != null)
                {
                    materialEditor.ShaderProperty(tint, new GUIContent("Main Color Tint"));
                }
                
                EditorGUI.indentLevel++;

                // Normal Map
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableNormalMap", "_NORMALMAP_ON", "Enable Normal Map", 
                    () => {
                        MaterialProperty normMap = FindProperty("_NormalMap", properties, false);
                        if (normMap != null) 
                        {
                            materialEditor.TexturePropertySingleLine(new GUIContent("Normal Map"), normMap);
                        }
                    });

                EditorGUILayout.Space(5);
                EditorGUILayout.LabelField("Cutout Settings", EditorStyles.boldLabel);
                FindProp("_CutoutNear", properties, materialEditor);
                FindProp("_CutoutFar", properties, materialEditor);
                
                MaterialProperty fadeDist = FindProperty("_CutoutFadeDistance", properties, false);
                if(fadeDist != null)
                {
                    materialEditor.ShaderProperty(fadeDist, new GUIContent(fadeDist.displayName, "Set to 0 to disable distance blending."));
                }

                FindProp("_Dither", properties, materialEditor);
                EditorGUI.indentLevel--;
            }

            // --- WIND SYSTEM ---
            EditorGUILayout.Space();
            showWind = EditorGUILayout.Foldout(showWind, "Wind System", true, foldoutStyle);
            if (showWind)
            {
                EditorGUI.indentLevel++;
                
                MaterialProperty noiseTex = FindProperty("_NoisePerlinWindAndColor", properties, false);
                if (noiseTex != null)
                {
                    materialEditor.TexturePropertySingleLine(new GUIContent("Global Noise (Required)"), noiseTex);
                }

                DrawToggleGroup(materialEditor, properties, 
                    "_EnableWind", "_WIND_ON", "Enable Wind Animation", 
                    () => {
                        FindProp("_WindDirection", properties, materialEditor);
                        FindProp("_WindSpeed", properties, materialEditor);
                        FindProp("_WindTiling", properties, materialEditor);
                        EditorGUILayout.Space(2);
                        FindProp("_WindMaxDistance", properties, materialEditor);
                    });

                EditorGUI.indentLevel--;
            }

            // --- STYLIZED LIGHTING & GRADIENT ---
            EditorGUILayout.Space();
            showStylized = EditorGUILayout.Foldout(showStylized, "Stylized Rendering", true, foldoutStyle);
            if (showStylized)
            {
                EditorGUI.indentLevel++;

                // Stylized Lit
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableStylized", "_STYLIZED_LIT_ON", "Enable Stylized Shadows", 
                    () => {
                        FindProp("_ShadowFlatness", properties, materialEditor);
                        FindProp("_SkyColor", properties, materialEditor);
                        FindProp("_GroundColor", properties, materialEditor);
                    });

                EditorGUILayout.Space(5);

                // Vertical Gradient
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableVerticalGradient", "_VERTICAL_GRADIENT_ON", "Enable Vertical Gradient", 
                    () => {
                        FindProp("_GradientStrength", properties, materialEditor);
                        FindProp("_GradientTop", properties, materialEditor);
                        FindProp("_GradientBottom", properties, materialEditor);
                        FindProp("_GradientHeight", properties, materialEditor);
                        FindProp("_GradientOffset", properties, materialEditor);
                    });

                EditorGUI.indentLevel--;
            }

            // --- COLOR VARIATION ---
            EditorGUILayout.Space();
            showVariation = EditorGUILayout.Foldout(showVariation, "Color Variation", true, foldoutStyle);
            if (showVariation)
            {
                EditorGUI.indentLevel++;

                // World Position Variation
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableVariation", "_VARIATION_ON", "World Position Variation", 
                    () => {
                        FindProp("_ColorSplit1", properties, materialEditor);
                        FindProp("_ColorSplit2", properties, materialEditor);
                        FindProp("_ColorVariationTiling", properties, materialEditor);
                        EditorGUILayout.HelpBox("Uses the Global Noise Texture defined in the Wind section.", MessageType.Info);
                    });

                EditorGUILayout.Space(5);

                // Instance Random Variation
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableInstanceVariation", "_INSTANCE_VARIATION_ON", "Instance Randomization", 
                    () => {
                        FindProp("_HueVariationColor", properties, materialEditor);
                        FindProp("_HueVariationStrength", properties, materialEditor);
                    });

                EditorGUI.indentLevel--;
            }

            // --- TRANSLUCENCY ---
            EditorGUILayout.Space();
            showTranslucency = EditorGUILayout.Foldout(showTranslucency, "Translucency", true, foldoutStyle);
            if (showTranslucency)
            {
                EditorGUI.indentLevel++;
                
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableTranslucency", "_TRANSLUCENCY_ON", "Enable Translucency", 
                    () => {
                        FindProp("_TransStrength", properties, materialEditor);
                        FindProp("_TransNormal", properties, materialEditor);
                        FindProp("_TransScattering", properties, materialEditor);
                        FindProp("_TransDirect", properties, materialEditor);
                        FindProp("_TransAmbient", properties, materialEditor);
                        FindProp("_TransShadow", properties, materialEditor);
                    });
                
                EditorGUI.indentLevel--;
            }

            // --- GROUND BLEND ---
            EditorGUILayout.Space();
            showGround = EditorGUILayout.Foldout(showGround, "Ground Blending", true, foldoutStyle);
            if (showGround)
            {
                EditorGUI.indentLevel++;
                
                DrawToggleGroup(materialEditor, properties, 
                    "_EnableGroundBlend", "_GROUND_BLEND_ON", "Enable Ground Blend", 
                    () => {
                        // Texture
                        MaterialProperty groundTex = FindProperty("_GroundTexture", properties, false);
                        if(groundTex != null) materialEditor.TexturePropertySingleLine(new GUIContent("Ground Texture"), groundTex);

                        // Tint
                        FindProp("_GroundColorTint", properties, materialEditor, "Ground Tint Color");

                        // Blend Strength
                        FindProp("_GroundBlendStrength", properties, materialEditor, "Blending Strength");

                        EditorGUILayout.Space(5);
                        EditorGUILayout.LabelField("Terrain Dimensions (1:1 Mapping)", EditorStyles.boldLabel);

                        // Terrain Size
                        MaterialProperty sizeProp = FindProperty("_TerrainSize", properties, false);
                        if (sizeProp != null)
                        {
                            EditorGUI.BeginChangeCheck();
                            Vector4 vec = sizeProp.vectorValue;
                            Vector2 vec2 = EditorGUILayout.Vector2Field("Terrain Size (X, Z)", new Vector2(vec.x, vec.y));
                            if (EditorGUI.EndChangeCheck())
                            {
                                sizeProp.vectorValue = new Vector4(vec2.x, vec2.y, vec.z, vec.w);
                            }
                        }
                        
                        // Terrain Pivot Position
                        MaterialProperty posProp = FindProperty("_TerrainPosition", properties, false);
                        if (posProp != null)
                        {
                            EditorGUI.BeginChangeCheck();
                            Vector4 vec = posProp.vectorValue;
                            Vector2 vec2 = EditorGUILayout.Vector2Field("Terrain Pivot (X, Z)", new Vector2(vec.x, vec.y));
                            if (EditorGUI.EndChangeCheck())
                            {
                                posProp.vectorValue = new Vector4(vec2.x, vec2.y, vec.z, vec.w);
                            }
                        }

                        // Terrain Pivot Offset
                        MaterialProperty offsetProp = FindProperty("_TerrainPivotOffset", properties, false);
                        if (offsetProp != null)
                        {
                            EditorGUI.BeginChangeCheck();
                            Vector4 vec = offsetProp.vectorValue;
                            Vector2 vec2 = EditorGUILayout.Vector2Field("Pivot Offset (X, Z)", new Vector2(vec.x, vec.y));
                            if (EditorGUI.EndChangeCheck())
                            {
                                offsetProp.vectorValue = new Vector4(vec2.x, vec2.y, vec.z, vec.w);
                            }
                        }

                        // Terrain Rotation
                        FindProp("_TerrainRotation", properties, materialEditor, "Terrain Y Rotation (Degrees)");
                    });

                EditorGUI.indentLevel--;
            }

            // --- ADVANCED ---
            EditorGUILayout.Space();
            showAdvanced = EditorGUILayout.Foldout(showAdvanced, "Advanced / Optimization", true, foldoutStyle);
            if (showAdvanced)
            {
                EditorGUI.indentLevel++;
                
                DrawToggleGroup(materialEditor, properties, 
                    "_CastShadows", null, "Cast Shadows (Optimization)", 
                    () => {
                        EditorGUILayout.HelpBox("Disables Shadow Caster pass for this material completely to save performance.", MessageType.None);
                    });

                EditorGUILayout.Space(5);

                // Culling options
                MaterialProperty cullProp = FindProperty("_Cull", properties, false);
                if(cullProp != null)
                {
                    EditorGUI.BeginChangeCheck();
                    var mode = (UnityEngine.Rendering.CullMode)((int)cullProp.floatValue);
                    mode = (UnityEngine.Rendering.CullMode)EditorGUILayout.EnumPopup("Culling Mode", mode);
                    if(EditorGUI.EndChangeCheck())
                    {
                        cullProp.floatValue = (float)mode;
                    }
                }

                materialEditor.RenderQueueField();
                materialEditor.EnableInstancingField();
                materialEditor.DoubleSidedGIField();
                EditorGUI.indentLevel--;
            }
        }

        // --- HELPERS ---

        void FindProp(string name, MaterialProperty[] props, MaterialEditor editor, string labelOverride = null)
        {
            MaterialProperty prop = FindProperty(name, props, false);
            if (prop != null)
            {
                editor.ShaderProperty(prop, labelOverride ?? prop.displayName);
            }
        }

        void DrawToggleGroup(MaterialEditor editor, MaterialProperty[] props, string propName, string keyword, string label, System.Action drawer)
        {
            MaterialProperty toggleProp = FindProperty(propName, props, false);
            if (toggleProp != null)
            {
                EditorGUI.BeginChangeCheck();
                editor.ShaderProperty(toggleProp, label);
                
                if (EditorGUI.EndChangeCheck())
                {
                    Material mat = editor.target as Material;
                    bool enabled = toggleProp.floatValue > 0.5f;

                    if (!string.IsNullOrEmpty(keyword))
                    {
                        if (enabled) mat.EnableKeyword(keyword);
                        else mat.DisableKeyword(keyword);
                    }

                    if (propName == "_CastShadows")
                    {
                        mat.SetShaderPassEnabled("ShadowCaster", enabled);
                    }
                }

                if (toggleProp.floatValue > 0.5f)
                {
                    EditorGUI.indentLevel++;
                    drawer.Invoke();
                    EditorGUI.indentLevel--;
                }
            }
        }
    }
}
#endif