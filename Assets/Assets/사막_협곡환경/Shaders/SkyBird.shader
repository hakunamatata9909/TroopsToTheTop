Shader "Custom/SkyBird"
{
    Properties
    {
        [Header(Base Textures)]
        [MainTexture] _BaseMap("Texture (Alpha)", 2D) = "white" {}
        [MainColor] _BaseColor("Tint Color", Color) = (1, 1, 1, 1)
        
        [Header(Cloud Wobble Settings)]
        [Toggle(_WOBBLE_ON)] _EnableWobble("Enable Cloud Wobble", Float) = 1
        _WobbleSpeed("Wobble Speed", Float) = 2.0
        _WobbleScale("Wobble Scale", Float) = 1.0
        _WobbleAmplitude("Wobble Amplitude", Float) = 0.5
        _WobbleScaleAmp("Wobble Scale Amplitude", Float) = 0.1

        [Header(Bird Flap Settings)]
        [Toggle(_BIRD_FLAP_ON)] _BirdFlap("Enable Bird Flapping", Float) = 0
        _WingSpeed("Wing Speed", Float) = 10.0
        _WingPower("Wing Power", Float) = 1.0
        _WingContrast("Wing Contrast", Float) = 3.0

        [Header(Translucency Settings)]
        [Toggle(_TRANSLUCENCY_ON)] _EnableTranslucency("Enable Translucency", Float) = 0
        _TransStrength("Trans Strength", Range(0, 50)) = 1
        _TransNormal("Trans Normal Distortion", Range(0, 1)) = 0.5
        _TransScattering("Trans Scattering", Range(1, 50)) = 2
        _TransDirect("Trans Direct", Range(0, 1)) = 0.9
        _TransAmbient("Trans Ambient", Range(0, 1)) = 0.1
        _TransShadow("Trans Shadow", Range(0, 1)) = 0.5

        // Hidden property injected via C# MaterialPropertyBlock to ensure stable desynchronization
        [HideInInspector] _InstanceRandom("Instance Random", Float) = 0.0
    }

    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent" 
            "RenderType"="Transparent" 
            "RenderPipeline"="UniversalPipeline" 
        }
        
        Blend SrcAlpha OneMinusSrcAlpha 
        ZWrite Off                      
        Cull Off                        

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            // Enable GPU Instancing for maximum performance
            #pragma multi_compile_instancing 
            
            // Compile keywords for lighting and shadows
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            // Local shader features controlled by the material toggles
            #pragma shader_feature_local _WOBBLE_ON
            #pragma shader_feature_local _BIRD_FLAP_ON
            #pragma shader_feature_local _TRANSLUCENCY_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            // Simple pseudo-random function based on 3D world position
            float Random(float3 pos)
            {
                return frac(sin(dot(pos.xyz, float3(12.9898, 78.233, 45.164))) * 43758.5453123);
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // ZMIANA TUTAJ: Zamiast "Props" używamy wymaganej nazwy "UnityPerMaterial"
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float, _InstanceRandom)
                
                UNITY_DEFINE_INSTANCED_PROP(float, _WobbleSpeed)
                UNITY_DEFINE_INSTANCED_PROP(float, _WobbleScale)
                UNITY_DEFINE_INSTANCED_PROP(float, _WobbleAmplitude)
                UNITY_DEFINE_INSTANCED_PROP(float, _WobbleScaleAmp)

                UNITY_DEFINE_INSTANCED_PROP(float, _WingSpeed)
                UNITY_DEFINE_INSTANCED_PROP(float, _WingPower)
                UNITY_DEFINE_INSTANCED_PROP(float, _WingContrast)

                UNITY_DEFINE_INSTANCED_PROP(float, _TransStrength)
                UNITY_DEFINE_INSTANCED_PROP(float, _TransNormal)
                UNITY_DEFINE_INSTANCED_PROP(float, _TransScattering)
                UNITY_DEFINE_INSTANCED_PROP(float, _TransDirect)
                UNITY_DEFINE_INSTANCED_PROP(float, _TransAmbient)
                UNITY_DEFINE_INSTANCED_PROP(float, _TransShadow)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            Varyings vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 modifiedPositionOS = input.positionOS.xyz;

                float3 objectOriginWS = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
                
                // ZMIANA TUTAJ: Wszędzie zamieniamy "Props" na "UnityPerMaterial"
                float randomVal = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _InstanceRandom);
                
                float speedVariation = lerp(0.7, 1.3, randomVal);
                float timeOffset = randomVal * 100.0; 

                #if defined(_WOBBLE_ON)
                    float wobSpeed = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WobbleSpeed) * speedVariation;
                    float wobScale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WobbleScale);
                    float wobAmp   = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WobbleAmplitude);
                    float wobScaleAmp = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WobbleScaleAmp);

                    float timeVar = (_Time.y + timeOffset) * wobSpeed;
                    
                    float wave = sin(input.positionOS.x * wobScale + timeVar) * cos(input.positionOS.z * wobScale + timeVar);
                    
                    modifiedPositionOS += input.normalOS * (wave * wobAmp);
                    modifiedPositionOS *= 1.0 + (wave * wobScaleAmp);
                #endif

                #if defined(_BIRD_FLAP_ON)
                    float wingSpeed = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WingSpeed) * speedVariation;
                    float wingPower = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WingPower);
                    float wingContr = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _WingContrast);

                    float pivot = 1.0 - input.uv.x;
                    float curve = pow(abs(pivot), wingContr);
                    
                    float flapWave = sin((_Time.y + timeOffset) * wingSpeed) * wingPower;
                    modifiedPositionOS += float3(0, 1, 0) * (curve * flapWave);
                #endif

                output.positionWS = TransformObjectToWorld(modifiedPositionOS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionCS = TransformObjectToHClip(modifiedPositionOS);
                output.uv = input.uv;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                // ZMIANA TUTAJ: Pobieranie właściwości przez "UnityPerMaterial"
                float4 tintColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float4 finalColor = texColor * tintColor;

                #if defined(_TRANSLUCENCY_ON)
                    float tNorm = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransNormal);
                    float tScat = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransScattering);
                    float tDir = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransDirect);
                    float tAmb = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransAmbient);
                    float tShadow = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransShadow);
                    float tStr = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _TransStrength);

                    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                    Light mainLight = GetMainLight(shadowCoord);
                    float3 bakedGI = SampleSH(input.normalWS);

                    float3 lightDir = mainLight.direction + normalize(input.normalWS) * tNorm;
                    float transDot = pow(saturate(dot(viewDirWS, -lightDir)), tScat);

                    float3 atten = mainLight.color * mainLight.distanceAttenuation;
                    float shadowAttenuation = lerp(1.0, mainLight.shadowAttenuation, tShadow);
                    
                    float3 transLight = atten * shadowAttenuation * (transDot * tDir + bakedGI * tAmb);
                    
                    finalColor.rgb += finalColor.rgb * transLight * tStr;
                #endif

                return finalColor;
            }
            ENDHLSL
        }
    }
}