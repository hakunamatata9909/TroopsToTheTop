Shader "Foliage RG Shader"
{
    Properties
    {
        [Header(Optimization)]
        [Toggle(_WIND_ON)] _EnableWind("Enable Wind", Float) = 1
        [Toggle] _CastShadows("Cast Shadows", Float) = 1
        [Toggle(_VARIATION_ON)] _EnableVariation("Enable World Color Variation", Float) = 1
        [Toggle(_GROUND_BLEND_ON)] _EnableGroundBlend("Enable Ground Blend", Float) = 1
        [Toggle(_TRANSLUCENCY_ON)] _EnableTranslucency("Enable Translucency", Float) = 1
        [Toggle(_NORMALMAP_ON)] _EnableNormalMap("Enable Normal Map", Float) = 1
        [Toggle(_VERTICAL_GRADIENT_ON)] _EnableVerticalGradient("Enable Vertical Gradient", Float) = 0
        [Toggle(_INSTANCE_VARIATION_ON)] _EnableInstanceVariation("Enable Instance Variation", Float) = 0
        [Toggle(_STYLIZED_LIT_ON)] _EnableStylized("Enable Stylized Lighting", Float) = 0

        [Header(Surface Options)]
        [MainColor] _Tint("Tint", Color) = (1,1,1,1)
        [MainTexture] _ColorTexture("Color Texture", 2D) = "white" {}
        [Normal] _NormalMap("Normal Map", 2D) = "bump" {}
        
        // --- GROUND BLEND PROPERTIES ---
        _GroundTexture("Ground Texture", 2D) = "white" {}
        _GroundColorTint("Ground Tint", Color) = (1,1,1,1)
        _TerrainSize("Terrain Size (X, Z)", Vector) = (500, 500, 0, 0)
        _TerrainPosition("Terrain Pivot Position (X, Z)", Vector) = (0, 0, 0, 0)
        _TerrainPivotOffset("Corner Offset from Pivot (X, Z)", Vector) = (0, 0, 0, 0)
        _TerrainRotation("Terrain Rotation Y (Degrees)", Float) = 0
        _GroundBlendStrength("Ground Blend Strength", Range(0, 1)) = 0.5
        // -------------------------------

        [Header(Stylized Options)]
        _ShadowFlatness("Shadow Flatness", Range(0, 1)) = 0.5
        _SkyColor("Shadow Sky Color", Color) = (0.2, 0.2, 0.5, 1)
        _GroundColor("Shadow Ground Color", Color) = (0.1, 0.05, 0.0, 1)

        [Header(Vertical Gradient)]
        _GradientBottom("Gradient Bottom Color", Color) = (0.2, 0.2, 0.2, 1)
        _GradientTop("Gradient Top Color", Color) = (1, 1, 0.8, 1)
        _GradientHeight("Gradient Height (Object Space)", Float) = 1.0
        _GradientOffset("Gradient Offset", Float) = 0.0
        _GradientStrength("Gradient Strength", Range(0, 1)) = 1.0

        [Header(Instance Variation)]
        _HueVariationColor("Hue Variation Tint", Color) = (1, 1, 0.5, 1)
        _HueVariationStrength("Variation Strength", Range(0, 1)) = 0.2

        [Header(Wind Parameters)]
        _WindDirection("Wind Direction", Vector) = (0,0,0,0)
        _WindSpeed("Wind Speed", Float) = 0
        _WindTiling("Wind Tiling", Float) = 0
        _WindMaxDistance("Wind Max Distance", Float) = 50.0 
        _NoisePerlinWindAndColor("Noise Texture (Wind & Color)", 2D) = "white" {}

        [Header(Color Variation World)]
        [HDR] _ColorSplit1("Color Split 1", Color) = (0,0,0,0)
        [HDR] _ColorSplit2("Color Split 2", Color) = (1,1,1,0)
        _ColorVariationTiling("Color Variation Tiling", Float) = 0
        
        [Header(Cutout and Fading)]
        _CutoutNear("Cutout Near", Range(0, 1)) = 0.5
        _CutoutFar("Cutout Far", Range(0, 1)) = 0.5
        _CutoutFadeDistance("Cutout Fade Distance", Range(0, 100)) = 0
        _Dither("Dither Strength", Range(0, 1)) = 0

        [Header(Translucency)]
        _TransStrength("Trans Strength", Range(0, 50)) = 1
        _TransNormal("Trans Normal Distortion", Range(0, 1)) = 0.5
        _TransScattering("Trans Scattering", Range(1, 50)) = 2
        _TransDirect("Trans Direct", Range(0, 1)) = 0.9
        _TransAmbient("Trans Ambient", Range(0, 1)) = 0.1
        _TransShadow("Trans Shadow", Range(0, 1)) = 0.5

        [HideInInspector] _Cull("__cull", Float) = 0.0
    }

    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalPipeline" 
            "RenderType"="Opaque" 
            "Queue"="Geometry" 
            "IgnoreProjector"="True"
        }

        LOD 300
        Cull [_Cull]
        ZWrite On
        ZTest LEqual

        HLSLINCLUDE
        // 1. ENABLE INSTANCING GLOBALLY
        #pragma multi_compile_instancing
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

        // 2. SETUP INSTANCING CBUFFER
        UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Tint)
            UNITY_DEFINE_INSTANCED_PROP(float4, _ColorTexture_ST)
            UNITY_DEFINE_INSTANCED_PROP(float4, _ColorSplit1)
            UNITY_DEFINE_INSTANCED_PROP(float4, _ColorSplit2)
            UNITY_DEFINE_INSTANCED_PROP(float3, _WindDirection)
            UNITY_DEFINE_INSTANCED_PROP(float, _WindSpeed)
            UNITY_DEFINE_INSTANCED_PROP(float, _WindTiling)
            UNITY_DEFINE_INSTANCED_PROP(float, _WindMaxDistance)
            UNITY_DEFINE_INSTANCED_PROP(float, _ColorVariationTiling)
            UNITY_DEFINE_INSTANCED_PROP(float, _CutoutNear)
            UNITY_DEFINE_INSTANCED_PROP(float, _CutoutFar)
            UNITY_DEFINE_INSTANCED_PROP(float, _CutoutFadeDistance)
            UNITY_DEFINE_INSTANCED_PROP(float, _Dither)
            
            UNITY_DEFINE_INSTANCED_PROP(float, _ShadowFlatness)
            UNITY_DEFINE_INSTANCED_PROP(float4, _SkyColor)
            UNITY_DEFINE_INSTANCED_PROP(float4, _GroundColor)

            UNITY_DEFINE_INSTANCED_PROP(float4, _GradientBottom)
            UNITY_DEFINE_INSTANCED_PROP(float4, _GradientTop)
            UNITY_DEFINE_INSTANCED_PROP(float, _GradientHeight)
            UNITY_DEFINE_INSTANCED_PROP(float, _GradientOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _GradientStrength)

            UNITY_DEFINE_INSTANCED_PROP(float4, _HueVariationColor)
            UNITY_DEFINE_INSTANCED_PROP(float, _HueVariationStrength)

            UNITY_DEFINE_INSTANCED_PROP(float, _TransStrength)
            UNITY_DEFINE_INSTANCED_PROP(float, _TransNormal)
            UNITY_DEFINE_INSTANCED_PROP(float, _TransScattering)
            UNITY_DEFINE_INSTANCED_PROP(float, _TransDirect)
            UNITY_DEFINE_INSTANCED_PROP(float, _TransAmbient)
            UNITY_DEFINE_INSTANCED_PROP(float, _TransShadow)

            // --- GROUND BLEND INSTANCED PROPS ---
            UNITY_DEFINE_INSTANCED_PROP(float4, _GroundColorTint)
            UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainSize)
            UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainPosition)
            UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainPivotOffset)
            UNITY_DEFINE_INSTANCED_PROP(float, _TerrainRotation)
            UNITY_DEFINE_INSTANCED_PROP(float, _GroundBlendStrength)
            // ------------------------------------

        UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

        sampler2D _ColorTexture;
        sampler2D _NormalMap;
        sampler2D _GroundTexture;
        sampler2D _NoisePerlinWindAndColor;

        inline float Dither8x8Bayer(int x, int y)
        {
            const float dither[64] = {
                1, 49, 13, 61,  4, 52, 16, 64,
                33, 17, 45, 29, 36, 20, 48, 32,
                9, 57,  5, 53, 12, 60,  8, 56,
                41, 25, 37, 21, 44, 28, 40, 24,
                3, 51, 15, 63,  2, 50, 14, 62,
                35, 19, 47, 31, 34, 18, 46, 30,
                11, 59,  7, 55, 10, 58,  6, 54,
                43, 27, 39, 23, 42, 26, 38, 22
            };
            int r = y * 8 + x;
            return dither[r] / 64.0;
        }

        float4 TriplanarSample(float3 worldPos, float3 worldNormal, float tiling)
        {
            float3 projNormal = pow(abs(worldNormal), 1.0);
            projNormal /= (projNormal.x + projNormal.y + projNormal.z) + 0.00001;
            float3 nsign = sign(worldNormal);
            float4 xNorm = tex2D(_NoisePerlinWindAndColor, tiling * worldPos.zy * float2(nsign.x, 1.0));
            float4 yNorm = tex2D(_NoisePerlinWindAndColor, tiling * worldPos.xz * float2(nsign.y, 1.0));
            float4 zNorm = tex2D(_NoisePerlinWindAndColor, tiling * worldPos.xy * float2(-nsign.z, 1.0));
            return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
        }

        float Random(float3 pos)
        {
            return frac(sin(dot(pos.xyz, float3(12.9898, 78.233, 45.164))) * 43758.5453123);
        }

        float3 ApplyWind(float3 positionOS, float vertexColorR, bool isShadowPass)
        {
            float3 worldPos = TransformObjectToWorld(positionOS);
            
            #if defined(_WIND_ON)
                float maxDist = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindMaxDistance);
                
                float dist = distance(_WorldSpaceCameraPos, worldPos);
                float distanceMask = 1.0 - saturate(dist / max(maxDist, 0.001));

                if (isShadowPass)
                {
                    distanceMask = 1.0; 
                }
                else
                {
                    if (distanceMask <= 0.0) return worldPos;
                }

                float speed = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindSpeed);
                float tiling = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindTiling);
                float3 wDir = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WindDirection);

                float2 panner = _Time.y * speed + (worldPos.xy * tiling);
                float4 noiseSample = tex2Dlod(_NoisePerlinWindAndColor, float4(panner, 0, 0));
                
                float3 invertedWind = wDir * -1.0;
                float3 finalDirection = lerp(wDir, invertedWind, noiseSample.r);
                
                float3 windOffset = noiseSample.r * finalDirection * vertexColorR * distanceMask;
                return worldPos + windOffset;
            #else
                return worldPos;
            #endif
        }

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float2 uv : TEXCOORD0;
            float2 lightmapUV : TEXCOORD1;
            float4 color : COLOR; 
            UNITY_VERTEX_INPUT_INSTANCE_ID 
        };

        struct VaryingsLit
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 positionWS : TEXCOORD1;
            float3 normalWS : TEXCOORD2;
            float3 viewDirWS : TEXCOORD3;
            float3 tangentWS : TEXCOORD4;
            float3 bitangentWS : TEXCOORD5;
            float heightOS : TEXCOORD6; 
            float4 vertexColor : COLOR;
            float fogFactor : TEXCOORD7;
            
            #ifdef LIGHTMAP_ON
                float2 lightmapUV : TEXCOORD8;
            #else
                float3 vertexSH : TEXCOORD8;
            #endif
            
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct VaryingsShadow
        {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 positionWS : TEXCOORD1;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        // --- VERTEX SHADERS ---

        VaryingsLit LitPassVertex(Attributes v)
        {
            VaryingsLit o;
            UNITY_SETUP_INSTANCE_ID(v); 
            UNITY_TRANSFER_INSTANCE_ID(v, o);

            float3 animatedWorldPos = ApplyWind(v.positionOS.xyz, v.color.r, false);
            
            o.positionWS = animatedWorldPos;
            o.positionCS = TransformWorldToHClip(animatedWorldPos);
            
            VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
            o.normalWS = normalInput.normalWS;
            o.tangentWS = normalInput.tangentWS;
            o.bitangentWS = normalInput.bitangentWS;

            o.viewDirWS = GetWorldSpaceViewDir(animatedWorldPos);
            
            float4 st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorTexture_ST);
            o.uv = v.uv * st.xy + st.zw;

            o.vertexColor = v.color;
            o.fogFactor = ComputeFogFactor(o.positionCS.z);
            o.heightOS = v.positionOS.y;

            #ifdef LIGHTMAP_ON
                o.lightmapUV = v.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
            #else
                o.vertexSH = SampleSH(o.normalWS);
            #endif

            return o;
        }

        VaryingsShadow ShadowPassVertex(Attributes v)
        {
            VaryingsShadow o;
            UNITY_SETUP_INSTANCE_ID(v); 
            
            float3 animatedWorldPos = ApplyWind(v.positionOS.xyz, v.color.r, true);
            
            o.positionWS = animatedWorldPos;
            
            float4 st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorTexture_ST);
            o.uv = v.uv * st.xy + st.zw;
            
            float3 normalWS = TransformObjectToWorldNormal(v.normalOS);
            o.positionCS = TransformWorldToHClip(animatedWorldPos);
            #if UNITY_REVERSED_Z
                o.positionCS.z = min(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                o.positionCS.z = max(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif

            return o;
        }

        // --- FRAGMENT HELPERS ---

        void DoAlphaClip(float4 positionCS, float3 positionWS, float2 uv)
        {
            float alphaCutoff = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _CutoutNear);
            float fadeDistVal = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _CutoutFadeDistance);
            float farCut = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _CutoutFar);
            float ditherVal = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Dither);

            if (fadeDistVal > 0.001)
            {
                float dist = distance(_WorldSpaceCameraPos, positionWS);
                alphaCutoff = lerp(alphaCutoff, farCut, dist / fadeDistVal);
            }

            float alpha = tex2D(_ColorTexture, uv).a;
            float2 screenPos = positionCS.xy;
            float dither = Dither8x8Bayer(fmod(screenPos.x, 8), fmod(screenPos.y, 8));
            dither = step(dither, alpha);
            float finalAlpha = lerp(alpha, dither, ditherVal);
            
            clip(finalAlpha - alphaCutoff);
        }

        // --- FRAGMENT SHADERS ---

        half4 LitPassFragment(VaryingsLit i) : SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(i);
            DoAlphaClip(i.positionCS, i.positionWS, i.uv);

            float4 col = tex2D(_ColorTexture, i.uv);
            
            float4 variationResult = float4(1,1,1,1);
            #if defined(_VARIATION_ON)
                float varTiling = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorVariationTiling);
                float4 split1 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorSplit1);
                float4 split2 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ColorSplit2);

                float4 noiseTriplanar = TriplanarSample(i.positionWS, normalize(i.normalWS), varTiling);
                float4 splitColor = lerp(split1, split2, noiseTriplanar.x);
                variationResult = lerp(splitColor, float4(1,1,1,1), i.vertexColor.b);
            #endif

            float4 tintCol = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Tint);
            float4 finalAlbedo = tintCol * col * variationResult;

            #if defined(_VERTICAL_GRADIENT_ON)
                float gOffset = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GradientOffset);
                float gHeight = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GradientHeight);
                float4 gBottom = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GradientBottom);
                float4 gTop = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GradientTop);
                float gradStrength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GradientStrength);

                float gradientFactor = saturate((i.heightOS - gOffset) / gHeight);
                float4 gradientCol = lerp(gBottom, gTop, gradientFactor);
                finalAlbedo = lerp(finalAlbedo, finalAlbedo * gradientCol, gradStrength);
            #endif

            #if defined(_INSTANCE_VARIATION_ON)
                float4 hueCol = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _HueVariationColor);
                float hueStr = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _HueVariationStrength);

                float3 objectOrigin = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
                float randomVal = Random(objectOrigin);
                finalAlbedo = lerp(finalAlbedo, finalAlbedo * hueCol, randomVal * hueStr);
            #endif

            // --- GROUND BLEND LOGIC UPDATE ---
            #if defined(_GROUND_BLEND_ON)
                float4 tSize = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TerrainSize);
                float4 tPos = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TerrainPosition);
                float4 tOffset = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TerrainPivotOffset);
                float tRot = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TerrainRotation);
                float blendStrength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GroundBlendStrength);
                float4 groundTint = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GroundColorTint);

                // 1. Odejmujemy PIVOT terenu (translacja do osi obrotu)
                float2 offsetWS = i.positionWS.xz - tPos.xy;

                // 2. Obracamy koordynaty wokół pivota
                float angle = radians(-tRot);
                float s = sin(angle);
                float c = cos(angle);
                
                float2 rotatedPos;
                rotatedPos.x = offsetWS.x * c - offsetWS.y * s;
                rotatedPos.y = offsetWS.x * s + offsetWS.y * c;

                // 3. Odejmujemy przesunięcie do rogu (UV 0,0) terenu
                rotatedPos -= tOffset.xy;

                // 4. Mapowanie 1:1 na podstawie rozmiaru
                float2 groundUV = rotatedPos / max(tSize.xy, float2(0.001, 0.001));
                
                float4 groundCol = tex2D(_GroundTexture, groundUV) * groundTint;
                finalAlbedo = lerp(finalAlbedo, groundCol, blendStrength);
            #endif
            // ---------------------------------
            
            InputData inputData = (InputData)0;
            inputData.positionWS = i.positionWS;
            
            float3 targetNormal = normalize(i.normalWS);
            #if defined(_NORMALMAP_ON)
                float3 unpackedNormal = UnpackNormal(tex2D(_NormalMap, i.uv));
                targetNormal = normalize(
                    unpackedNormal.x * i.tangentWS + 
                    unpackedNormal.y * i.bitangentWS + 
                    unpackedNormal.z * i.normalWS
                );
            #endif

            #if defined(_STYLIZED_LIT_ON)
                float sFlatness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ShadowFlatness);
                float4 sSky = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SkyColor);
                float4 sGround = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _GroundColor);

                inputData.normalWS = normalize(lerp(targetNormal, normalize(i.normalWS), sFlatness));
                float gradientMask = saturate(inputData.normalWS.y * 0.5 + 0.5);
                float3 ambientTint = lerp(sGround.rgb, sSky.rgb, gradientMask);
                finalAlbedo.rgb *= ambientTint;
            #else
                inputData.normalWS = targetNormal;
            #endif

            inputData.viewDirectionWS = normalize(i.viewDirWS);
            inputData.shadowCoord = TransformWorldToShadowCoord(i.positionWS);
            inputData.fogCoord = i.fogFactor;

            #ifdef LIGHTMAP_ON
                inputData.bakedGI = SAMPLE_GI(i.lightmapUV, half3(0,0,0), inputData.normalWS);
            #else
                inputData.bakedGI = SAMPLE_GI(float2(0,0), i.vertexSH, inputData.normalWS);
            #endif

            SurfaceData surfaceData = (SurfaceData)0;
            surfaceData.albedo = finalAlbedo.rgb;
            surfaceData.alpha = 1.0; 
            surfaceData.occlusion = 1;
            surfaceData.smoothness = 0;
            surfaceData.metallic = 0;
            
            half4 finalColor = UniversalFragmentPBR(inputData, surfaceData);

            // --- TRANSLUCENCY FIX: Usunięto warunek _MAIN_LIGHT_SHADOWS ---
            #if defined(_TRANSLUCENCY_ON)
                float tNorm = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransNormal);
                float tScat = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransScattering);
                float tDir = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransDirect);
                float tAmb = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransAmbient);
                float tShadow = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransShadow);
                float tStr = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransStrength);

                Light mainLight = GetMainLight(inputData.shadowCoord);
                float3 lightDir = mainLight.direction + normalize(i.normalWS) * tNorm;
                float transDot = pow(saturate(dot(inputData.viewDirectionWS, -lightDir)), tScat);
                
                float3 atten = mainLight.color * mainLight.distanceAttenuation;
                float shadowAttenuation = lerp(1.0, mainLight.shadowAttenuation, tShadow);
                float3 transLight = atten * shadowAttenuation * (transDot * tDir + inputData.bakedGI * tAmb);
                
                finalColor.rgb += surfaceData.albedo * transLight * tStr;
            #endif
            // --------------------------------------------------------------

            finalColor.rgb = MixFog(finalColor.rgb, i.fogFactor);
            return finalColor;
        }

        half4 ShadowDepthPassFragment(VaryingsShadow i) : SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(i);
            DoAlphaClip(i.positionCS, i.positionWS, i.uv);
            return 0;
        }

        ENDHLSL

        // 1. FORWARD LIT PASS
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON
            
            #pragma shader_feature_local _WIND_ON
            #pragma shader_feature_local _VARIATION_ON
            #pragma shader_feature_local _GROUND_BLEND_ON
            #pragma shader_feature_local _TRANSLUCENCY_ON
            #pragma shader_feature_local _NORMALMAP_ON
            #pragma shader_feature_local _VERTICAL_GRADIENT_ON
            #pragma shader_feature_local _INSTANCE_VARIATION_ON
            #pragma shader_feature_local _STYLIZED_LIT_ON
            ENDHLSL
        }

        // 2. SHADOW CASTER PASS
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowDepthPassFragment
            
            #pragma shader_feature_local _WIND_ON
            ENDHLSL
        }

        // 3. DEPTH ONLY PASS
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowDepthPassFragment
            
            #pragma shader_feature_local _WIND_ON
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "RGTools.FoliageShaderGUI"
}