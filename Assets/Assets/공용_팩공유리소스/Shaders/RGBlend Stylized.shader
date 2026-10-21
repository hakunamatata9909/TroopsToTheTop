Shader "Custom/RGBlend_Hybrid_Stylized_Final"
{
    Properties
    {
        // --- DEBUG TOOLS ---
        [Header(Debug Tools)]
        [KeywordEnum(None, Vertex_R, Vertex_G, World_Normal, Smoothness, AO, Metallic, Gradient_View)] _Debug ("Debug View", Float) = 0

        // --- BASE LAYER ---
        [Header(Base Layer)]
        [Toggle(_BASE_WORLD_UV)] _BaseUseWorldUV ("Use World UV (Base)", Float) = 0
        [MainTexture] _BaseMap ("Base Albedo (RGB) + Height (A)", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color Tint", Color) = (1,1,1,1)
        [Normal] _BaseNormal ("Base Normal", 2D) = "bump" {}
        _BaseMask ("Base Mask (R=AO, G=Roughness, B=Met)", 2D) = "white" {}
        _BaseSmoothness ("Base Smoothness", Range(0, 1)) = 1.0
        _BaseTiling ("Base Tiling", Float) = 1.0
        _BaseNormalScale ("Base Normal Scale", Range(0, 2)) = 1.0
        
        // --- LAYER R ---
        [Header(Layer R)]
        [Toggle(_LAYER_R)] _EnableLayerR ("Enable Layer R", Float) = 1
        [Toggle(_R_WORLD_UV)] _RUseWorldUV ("Use World UV (Layer R)", Float) = 0
        _RMap ("R Albedo (RGB) + Height (A)", 2D) = "white" {}
        _RColor ("R Color Tint", Color) = (0.9,0.9,0.9,1)
        [Normal] _RNormal ("R Normal", 2D) = "bump" {}
        _RMask ("R Mask (R=AO, G=Roughness, B=Met)", 2D) = "white" {}
        _RSmoothness ("R Smoothness", Range(0, 1)) = 1.0
        _RTiling ("R Tiling", Float) = 1.0
        _RNormalScale ("R Normal Scale", Range(0, 2)) = 1.0
        _BlendBiasR ("Blend Bias R", Range(0, 1)) = 0.5
        _BlendContrastR ("Blend Contrast R", Range(1, 50)) = 10.0

        // --- LAYER G ---
        [Header(Layer G)]
        [Toggle(_LAYER_G)] _EnableLayerG ("Enable Layer G", Float) = 1
        [Toggle(_G_WORLD_UV)] _GUseWorldUV ("Use World UV (Layer G)", Float) = 0
        _GMap ("G Albedo (RGB) + Height (A)", 2D) = "white" {}
        _GColor ("G Color Tint", Color) = (1,1,1,1)
        [Normal] _GNormal ("G Normal", 2D) = "bump" {}
        _GMask ("G Mask (R=AO, G=Roughness, B=Met)", 2D) = "white" {}
        _GSmoothness ("G Smoothness", Range(0, 1)) = 1.0
        _GTiling ("G Tiling", Float) = 1.0
        _GNormalScale ("G Normal Scale", Range(0, 2)) = 1.0
        _BlendBiasG ("Blend Bias G", Range(0, 1)) = 0.5
        _BlendContrastG ("Blend Contrast G", Range(1, 50)) = 10.0

        // --- DETAIL LAYER ---
        [Header(Detail Layer)]
        [Toggle(_DETAIL_LAYER)] _EnableDetailLayer ("Enable Detail Layer", Float) = 0
        [Enum(All Layers,0, Base Only,1, Layer R Only,2, Layer G Only,3, Base And R,4, Base And G,5, R And G,6)] _DetailTarget ("Apply Detail To", Float) = 0
        _DetailMap ("Detail Albedo (Gray = Neutral)", 2D) = "gray" {}
        _DetailColor ("Detail Tint", Color) = (1,1,1,1)
        _DetailTiling ("Detail Tiling", Float) = 10.0
        _DetailStrength ("Detail Strength", Range(0, 1)) = 1.0

        // --- VERTICAL GRADIENT ---
        [Header(Vertical Gradient)]
        [Toggle(_GRADIENT_ON)] _EnableGradient ("Enable Advanced Gradient", Float) = 0
        
        [KeywordEnum(Object, World)] _GradientSpace ("Coordinate Space", Float) = 0
        _GradientNoiseMap ("Gradient Noise (R)", 2D) = "black" {}
        _GradientNoiseScale ("Noise Tiling", Float) = 1.0
        _GradientNoiseStrength ("Noise Distortion Strength", Range(0, 5)) = 0.5
        
        // Bottom
        _GradientBottomColor ("Bottom Color", Color) = (0.1, 0.08, 0.05, 1)
        _GradientBottomPos ("Bottom Start Y", Float) = 0.0
        _GradientBottomSoftness ("Bottom Softness", Float) = 2.0
        _GradientBottomIntensity ("Bottom Opacity", Range(0, 1)) = 1.0 // <-- NOWE

        // Top
        _GradientTopColor ("Top Color", Color) = (1, 1, 0.9, 1)
        _GradientTopPos ("Top Start Y", Float) = 5.0
        _GradientTopSoftness ("Top Softness", Float) = 2.0
        _GradientTopIntensity ("Top Opacity", Range(0, 1)) = 1.0 // <-- NOWE

        // --- GLOBAL ---
        [Header(Global Settings)]
        _OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1
        _WorldUVScale ("Global World UV Scale", Float) = 0.0666 

        // --- STYLIZED ---
        [Header(Stylized Options)]
        [Toggle(_STYLIZED_LIT)] _EnableStylized ("Enable Stylized Lighting", Float) = 0
        _ShadowFlatness ("Shadow Flatness", Range(0, 1)) = 0.5
        _SkyColor ("Sky Color (AO Tint)", Color) = (0.2, 0.2, 0.5, 1)
        _GroundColor ("Ground Color (AO Tint)", Color) = (0.1, 0.05, 0.0, 1)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        LOD 300

        // ------------------------------------------------------------------
        // PASS 1: FORWARD LIT
        // ------------------------------------------------------------------
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            ZWrite On Blend One Zero Cull Back

            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag

            // Keywords
            #pragma shader_feature_local _BASE_WORLD_UV
            #pragma shader_feature_local _R_WORLD_UV
            #pragma shader_feature_local _G_WORLD_UV
            
            #pragma shader_feature_local _LAYER_R
            #pragma shader_feature_local _LAYER_G
            #pragma shader_feature_local _DETAIL_LAYER 
            #pragma shader_feature_local _GRADIENT_ON 
            #pragma shader_feature_local _GRADIENTSPACE_OBJECT _GRADIENTSPACE_WORLD
            
            #pragma shader_feature_local _STYLIZED_LIT 
            #pragma shader_feature_local _DEBUG_NONE _DEBUG_VERTEX_R _DEBUG_VERTEX_G _DEBUG_WORLD_NORMAL _DEBUG_SMOOTHNESS _DEBUG_AO _DEBUG_METALLIC _DEBUG_GRADIENT_VIEW

            #pragma multi_compile_fog 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor, _RColor, _GColor;
                float _BaseTiling, _BaseNormalScale, _BaseSmoothness;
                float _RTiling, _RNormalScale, _BlendBiasR, _BlendContrastR, _RSmoothness;
                float _GTiling, _GNormalScale, _BlendBiasG, _BlendContrastG, _GSmoothness;
                
                float4 _DetailColor;
                float _DetailTiling, _DetailStrength, _DetailTarget;

                float4 _GradientBottomColor, _GradientTopColor;
                float _GradientBottomPos, _GradientBottomSoftness, _GradientBottomIntensity; // <--- Dodane do CBUFFER
                float _GradientTopPos, _GradientTopSoftness, _GradientTopIntensity;       // <--- Dodane do CBUFFER
                float _GradientNoiseScale, _GradientNoiseStrength;

                float _OcclusionStrength;
                float _WorldUVScale;
                float _ShadowFlatness;
                float4 _SkyColor, _GroundColor;
                float _Debug;
            CBUFFER_END

            TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BaseNormal); SAMPLER(sampler_BaseNormal);
            TEXTURE2D(_BaseMask);   SAMPLER(sampler_BaseMask);

            TEXTURE2D(_RMap);       SAMPLER(sampler_RMap);
            TEXTURE2D(_RNormal);    SAMPLER(sampler_RNormal);
            TEXTURE2D(_RMask);      SAMPLER(sampler_RMask);

            TEXTURE2D(_GMap);       SAMPLER(sampler_GMap);
            TEXTURE2D(_GNormal);    SAMPLER(sampler_GNormal);
            TEXTURE2D(_GMask);      SAMPLER(sampler_GMask);

            TEXTURE2D(_DetailMap);  SAMPLER(sampler_DetailMap);
            TEXTURE2D(_GradientNoiseMap); SAMPLER(sampler_GradientNoiseMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float2 staticLightmapUV : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float4 color : COLOR;
                float4 tangentWS : TEXCOORD4;
                half4 fogFactorAndVertexLight : TEXCOORD5;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 6);
                float3 positionOS_Gradient : TEXCOORD7; 
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                output.uv = input.uv;
                output.color = input.color;
                
                real sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(normalInput.tangentWS, sign);

                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS, output.vertexSH);

                half3 vertexLight = VertexLighting(output.positionWS, output.normalWS);
                half fogFactor = ComputeFogFactor(output.positionCS.z);
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                output.positionOS_Gradient = input.positionOS.xyz;

                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                // 0. DETAIL MODIFIER
                float3 finalDetailMod = float3(1,1,1);
                #if defined(_DETAIL_LAYER)
                    float2 uvDetail = input.uv * _DetailTiling;
                    half3 detailSample = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, uvDetail).rgb;
                    detailSample *= _DetailColor.rgb;
                    float3 rawMod = detailSample * 2.0;
                    finalDetailMod = lerp(float3(1,1,1), rawMod, _DetailStrength);
                #endif

                int target = (int)_DetailTarget;
                bool applyBase = (target == 0 || target == 1 || target == 4 || target == 5);
                bool applyR    = (target == 0 || target == 2 || target == 4 || target == 6);
                bool applyG    = (target == 0 || target == 3 || target == 5 || target == 6);

                // 1. BASE LAYER
                float2 uvBase = input.uv * _BaseTiling;
                #if defined(_BASE_WORLD_UV)
                    uvBase = input.positionWS.xz * _WorldUVScale; 
                #endif

                half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvBase) * _BaseColor;
                #if defined(_DETAIL_LAYER)
                    if(applyBase) 
                        baseCol.rgb *= finalDetailMod;
                #endif

                half3 baseNrm = UnpackNormalScale(SAMPLE_TEXTURE2D(_BaseNormal, sampler_BaseNormal, uvBase), _BaseNormalScale);
                half4 baseMask = SAMPLE_TEXTURE2D(_BaseMask, sampler_BaseMask, uvBase); 
                
                float baseS = saturate((1.0 - baseMask.g) * _BaseSmoothness);
                float baseMet = baseMask.b;
                float baseAO = baseMask.r;

                half3 finalAlbedo = baseCol.rgb;
                half3 finalNormalTS = baseNrm;
                float finalSmoothness = baseS;
                float finalMetallic = baseMet;
                float finalAO = baseAO;

                // 2. LAYER R
                #if defined(_LAYER_R)
                    float2 uvR = input.uv * _RTiling;
                    #if defined(_R_WORLD_UV)
                        uvR = input.positionWS.xz * _WorldUVScale;
                    #endif
                    half4 rCol = SAMPLE_TEXTURE2D(_RMap, sampler_RMap, uvR);
                    
                    #if defined(_DETAIL_LAYER)
                        if(applyR) 
                            rCol.rgb *= (finalDetailMod * _RColor.rgb);
                        else 
                            rCol.rgb *= _RColor.rgb;
                    #else
                        rCol.rgb *= _RColor.rgb;
                    #endif

                    half3 rNrm = UnpackNormalScale(SAMPLE_TEXTURE2D(_RNormal, sampler_RNormal, uvR), _RNormalScale);
                    half4 rMask = SAMPLE_TEXTURE2D(_RMask, sampler_RMask, uvR);
                    
                    float rS = saturate((1.0 - rMask.g) * _RSmoothness);
                    float rMet = rMask.b;
                    float rAO = rMask.r;
                    float rRaw = input.color.r * rCol.a;
                    float wR = saturate((rRaw - _BlendBiasR) * _BlendContrastR);

                    finalAlbedo = lerp(finalAlbedo, rCol.rgb, wR);
                    finalNormalTS = normalize(lerp(finalNormalTS, rNrm, wR));
                    finalSmoothness = lerp(finalSmoothness, rS, wR);
                    finalMetallic = lerp(finalMetallic, rMet, wR);
                    finalAO = lerp(finalAO, rAO, wR);
                #endif

                // 3. LAYER G
                #if defined(_LAYER_G)
                    float2 uvG = input.uv * _GTiling;
                    #if defined(_G_WORLD_UV)
                        uvG = input.positionWS.xz * _WorldUVScale;
                    #endif
                    half4 gCol = SAMPLE_TEXTURE2D(_GMap, sampler_GMap, uvG);
                    
                    #if defined(_DETAIL_LAYER)
                        if(applyG) 
                            gCol.rgb *= (finalDetailMod * _GColor.rgb);
                        else 
                            gCol.rgb *= _GColor.rgb;
                    #else
                        gCol.rgb *= _GColor.rgb;
                    #endif

                    half3 gNrm = UnpackNormalScale(SAMPLE_TEXTURE2D(_GNormal, sampler_GNormal, uvG), _GNormalScale);
                    half4 gMask = SAMPLE_TEXTURE2D(_GMask, sampler_GMask, uvG);
                    
                    float gS = saturate((1.0 - gMask.g) * _GSmoothness);
                    float gMet = gMask.b;
                    float gAO = gMask.r;
                    float gRaw = input.color.g * gCol.a;
                    float wG = saturate((gRaw - _BlendBiasG) * _BlendContrastG);

                    finalAlbedo = lerp(finalAlbedo, gCol.rgb, wG);
                    finalNormalTS = normalize(lerp(finalNormalTS, gNrm, wG));
                    finalSmoothness = lerp(finalSmoothness, gS, wG);
                    finalMetallic = lerp(finalMetallic, gMet, wG);
                    finalAO = lerp(finalAO, gAO, wG);
                #endif

                // 4. VERTICAL GRADIENT (With Opacity/Intensity Controls)
                #if defined(_GRADIENT_ON)
                    float currentY = 0;
                    #if defined(_GRADIENTSPACE_OBJECT)
                        currentY = input.positionOS_Gradient.y;
                    #else
                        currentY = input.positionWS.y;
                    #endif

                    float noise = SAMPLE_TEXTURE2D(_GradientNoiseMap, sampler_GradientNoiseMap, input.uv * _GradientNoiseScale).r;
                    float perturbedY = currentY + (noise - 0.5) * _GradientNoiseStrength;

                    // Calculate Mask (0..1)
                    float bottomMask = saturate((_GradientBottomPos - perturbedY) / max(0.001, _GradientBottomSoftness));
                    float topMask = saturate((perturbedY - _GradientTopPos) / max(0.001, _GradientTopSoftness));

                    // Apply Intensity (Opacity)
                    // We blend using (Mask * Intensity)
                    // If Intensity is 0, we blend 0% of the gradient color (invisible).
                    // We also consider the Color Alpha channel for consistency.
                    
                    float bottomBlendFactor = bottomMask * _GradientBottomIntensity * _GradientBottomColor.a;
                    float topBlendFactor = topMask * _GradientTopIntensity * _GradientTopColor.a;

                    finalAlbedo = lerp(finalAlbedo, _GradientBottomColor.rgb, bottomBlendFactor);
                    finalAlbedo = lerp(finalAlbedo, _GradientTopColor.rgb, topBlendFactor);
                #endif

                float occlusion = lerp(1.0, finalAO, _OcclusionStrength);

                // 5. DATA PREP
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.positionCS = input.positionCS;
                
                half3 bitangent = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitangent, input.normalWS);
                
                #if defined(_STYLIZED_LIT)
                    float3 pixelNormal = TransformTangentToWorld(finalNormalTS, TBN);
                    float3 geometryNormal = NormalizeNormalPerPixel(input.normalWS);
                    inputData.normalWS = normalize(lerp(pixelNormal, geometryNormal, _ShadowFlatness));
                    float gradientMask = saturate(inputData.normalWS.y * 0.5 + 0.5); 
                    float3 ambientTint = lerp(_GroundColor.rgb, _SkyColor.rgb, gradientMask);
                    finalAlbedo = finalAlbedo * lerp(ambientTint, float3(1,1,1), occlusion);
                    occlusion = 1.0; 
                #else
                    inputData.normalWS = TransformTangentToWorld(finalNormalTS, TBN);
                    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                #endif

                inputData.viewDirectionWS = input.viewDirWS;
                inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                inputData.fogCoord = 0; 
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;

                // 6. OUTPUT
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = finalAlbedo;
                surfaceData.metallic = finalMetallic;
                surfaceData.smoothness = finalSmoothness;
                surfaceData.normalTS = finalNormalTS;
                surfaceData.occlusion = occlusion;
                surfaceData.alpha = 1.0;

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, input.fogFactorAndVertexLight.x);

                // DEBUG
                #if !defined(_DEBUG_NONE)
                    half3 debugColor = half3(0,0,0);
                    #if defined(_DEBUG_VERTEX_R)
                        debugColor = half3(input.color.r, 0, 0); 
                    #elif defined(_DEBUG_VERTEX_G)
                        debugColor = half3(0, input.color.g, 0);
                    #elif defined(_DEBUG_WORLD_NORMAL)
                        debugColor = inputData.normalWS * 0.5 + 0.5;
                    #elif defined(_DEBUG_SMOOTHNESS)
                        debugColor = half3(finalSmoothness, finalSmoothness, finalSmoothness);
                    #elif defined(_DEBUG_AO)
                        debugColor = half3(finalAO, finalAO, finalAO);
                    #elif defined(_DEBUG_METALLIC)
                        debugColor = half3(finalMetallic, finalMetallic, finalMetallic);
                    #elif defined(_DEBUG_GRADIENT_VIEW)
                        #if defined(_GRADIENT_ON)
                            float dbgY = 0;
                            #if defined(_GRADIENTSPACE_OBJECT)
                                dbgY = input.positionOS_Gradient.y;
                            #else
                                dbgY = input.positionWS.y;
                            #endif
                            float dbgNoise = SAMPLE_TEXTURE2D(_GradientNoiseMap, sampler_GradientNoiseMap, input.uv * _GradientNoiseScale).r;
                            float dbgPert = dbgY + (dbgNoise - 0.5) * _GradientNoiseStrength;
                            
                            // Debug masks logic including Intensity
                            float bM = saturate((_GradientBottomPos - dbgPert) / max(0.001, _GradientBottomSoftness)) * _GradientBottomIntensity;
                            float tM = saturate((dbgPert - _GradientTopPos) / max(0.001, _GradientTopSoftness)) * _GradientTopIntensity;
                            
                            debugColor = float3(0.5,0.5,0.5);
                            debugColor = lerp(debugColor, _GradientBottomColor.rgb, bM);
                            debugColor = lerp(debugColor, _GradientTopColor.rgb, tM);
                        #else
                            debugColor = float3(1,0,1); 
                        #endif
                    #endif
                    return half4(debugColor, 1.0);
                #endif

                return color;
            }
            ENDHLSL
        }

        // --- SHADOW CASTER ---
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On ZTest LEqual ColorMask 0
            
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor; float4 _BaseMap_ST;
            CBUFFER_END
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        // --- DEPTH ONLY ---
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            ZWrite On ColorMask 0
            
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor; float4 _BaseMap_ST;
            CBUFFER_END
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // --- DEPTH NORMALS ---
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            ZWrite On
            
            HLSLPROGRAM
            #pragma target 4.5
            #pragma vertex Vert
            #pragma fragment Frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            #pragma shader_feature_local _BASE_WORLD_UV
            #pragma shader_feature_local _R_WORLD_UV
            #pragma shader_feature_local _G_WORLD_UV
            #pragma shader_feature_local _LAYER_R
            #pragma shader_feature_local _LAYER_G
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor, _RColor, _GColor;
                float _BaseTiling, _BaseNormalScale, _BaseSmoothness; 
                float _RTiling, _RNormalScale, _BlendBiasR, _BlendContrastR, _RSmoothness;
                float _GTiling, _GNormalScale, _BlendBiasG, _BlendContrastG, _GSmoothness;
                float4 _DetailColor;
                float _DetailTiling, _DetailStrength, _DetailTarget;
                
                // Gradient Padding
                float4 _GradientBottomColor, _GradientTopColor;
                float _GradientBottomPos, _GradientBottomSoftness, _GradientBottomIntensity;
                float _GradientTopPos, _GradientTopSoftness, _GradientTopIntensity;
                float _GradientNoiseScale, _GradientNoiseStrength;

                float _OcclusionStrength;
                float _WorldUVScale;
                float _ShadowFlatness;
                float4 _SkyColor, _GroundColor;
                float _Debug;
            CBUFFER_END

            TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BaseNormal); SAMPLER(sampler_BaseNormal);
            TEXTURE2D(_RMap);       SAMPLER(sampler_RMap);
            TEXTURE2D(_RNormal);    SAMPLER(sampler_RNormal);
            TEXTURE2D(_GMap);       SAMPLER(sampler_GMap);
            TEXTURE2D(_GNormal);    SAMPLER(sampler_GNormal);

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0; 
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float4 color : COLOR;
            };

            Varyings Vert(Attributes input) {
                Varyings output;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS; 
                output.normalWS = normalInput.normalWS;
                output.uv = input.uv;
                output.color = input.color;
                real sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(normalInput.tangentWS, sign);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target {
                float2 uvBase = input.uv * _BaseTiling;
                #if defined(_BASE_WORLD_UV)
                    uvBase = input.positionWS.xz * _WorldUVScale;
                #endif
                half3 baseNrm = UnpackNormalScale(SAMPLE_TEXTURE2D(_BaseNormal, sampler_BaseNormal, uvBase), _BaseNormalScale);
                half3 finalNormalTS = baseNrm;

                #if defined(_LAYER_R)
                    float2 uvR = input.uv * _RTiling;
                    #if defined(_R_WORLD_UV)
                        uvR = input.positionWS.xz * _WorldUVScale;
                    #endif
                    half3 rNrm = UnpackNormalScale(SAMPLE_TEXTURE2D(_RNormal, sampler_RNormal, uvR), _RNormalScale);
                    float rHeight = SAMPLE_TEXTURE2D(_RMap, sampler_RMap, uvR).a;
                    float rRaw = input.color.r * rHeight;
                    float wR = saturate((rRaw - _BlendBiasR) * _BlendContrastR);
                    finalNormalTS = normalize(lerp(finalNormalTS, rNrm, wR));
                #endif

                #if defined(_LAYER_G)
                    float2 uvG = input.uv * _GTiling;
                    #if defined(_G_WORLD_UV)
                        uvG = input.positionWS.xz * _WorldUVScale;
                    #endif
                    half3 gNrm = UnpackNormalScale(SAMPLE_TEXTURE2D(_GNormal, sampler_GNormal, uvG), _GNormalScale);
                    float gHeight = SAMPLE_TEXTURE2D(_GMap, sampler_GMap, uvG).a;
                    float gRaw = input.color.g * gHeight;
                    float wG = saturate((gRaw - _BlendBiasG) * _BlendContrastG);
                    finalNormalTS = normalize(lerp(finalNormalTS, gNrm, wG));
                #endif

                half3 bitangent = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
                half3x3 TBN = half3x3(input.tangentWS.xyz, bitangent, input.normalWS);
                float3 normalWS = TransformTangentToWorld(finalNormalTS, TBN);
                normalWS = NormalizeNormalPerPixel(normalWS);
                return float4(normalWS, 0.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "RGTools.RGBlendStylizedGUI"
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}