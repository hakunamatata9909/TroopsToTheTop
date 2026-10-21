Shader "Custom/BackgroundTerrain"
{
    Properties
    {
        [Header(Main Texture)]
        // Zmieniono podpowiedź na (A = Alpha) - używamy teraz właściwego kanału z pliku PNG
        [MainTexture] _Mask("Mask Texture (A = Alpha)", 2D) = "white" {}
        
        [Header(Color Gradient)]
        _ColorTop("Top Color", Color) = (0.2, 0.5, 1.0, 1)
        _ColorBottom("Bottom Color", Color) = (1.0, 0.5, 0.2, 1)
        
        [Header(UV Settings and Animation)]
        _Tiling("Tiling (X, Y)", Vector) = (1, 1, 0, 0)
        _Offset("Y Offset (Vertical)", Float) = 0.0
        _ScrollSpeed("Scroll Speed (X, Y)", Vector) = (0.05, 0, 0, 0)
        
        [Header(Fake Height Fog)]
        _FogColor("Custom Fog Color", Color) = (0.8, 0.9, 1.0, 1)
        _Fog_Height("Fog Height Power", Float) = 5.0

        [Header(Transparency)]
        _GlobalAlpha("Global Opacity", Range(0.0, 1.0)) = 1.0
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Transparent" 
            "Queue"="Transparent" 
            "RenderPipeline"="UniversalPipeline" 
        }

        Blend SrcAlpha OneMinusSrcAlpha 
        ZWrite Off                      
        Cull Back                       

        Pass
        {
            Name "Unlit"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            TEXTURE2D(_Mask);
            SAMPLER(sampler_Mask);

            CBUFFER_START(UnityPerMaterial)
                float4 _ColorTop;
                float4 _ColorBottom;
                float4 _Tiling;
                float4 _ScrollSpeed;
                float  _Offset;
                float4 _FogColor;
                float  _Fog_Height;
                float  _GlobalAlpha;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 1. SCROLLING (UV Animation)
                float2 animatedUV = input.uv * _Tiling.xy + float2(0.0, _Offset) + (_ScrollSpeed.xy * _Time.y);

                // 2. TEXTURE SAMPLE
                half4 texColor = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, animatedUV);

                // 3. VERTICAL COLOR GRADIENT
                half3 gradientTint = lerp(_ColorBottom.rgb, _ColorTop.rgb, input.uv.y);
                half3 baseColor = texColor.rgb * gradientTint;

                // 4. HEIGHT FOG
                float invertedY = saturate(1.0 - input.uv.y);
                float fogFactor = pow(invertedY, max(0.0001, _Fog_Height));
                half3 finalRGB = lerp(baseColor, _FogColor.rgb, fogFactor);

                // 5. TRANSPARENCY (ALPHA) FIX
                // Używamy texColor.a (prawdziwej przezroczystości z pliku graficznego)
                // Ignorujemy przezroczystość ustawioną w gradientach, opierając się tylko na suwaku Global Opacity
                half finalAlpha = texColor.a * _GlobalAlpha;

                return half4(finalRGB, finalAlpha);
            }
            ENDHLSL
        }
    }
}