// Stylized clear water for URP: refracted seabed, soft caustics, small ripples,
// sun glints, sky reflection and a thin shore foam line.
// Needs Depth Texture and Opaque Texture enabled on the URP asset (or camera).
Shader "RG Poly/Chibi Water"
{
    Properties
    {
        [Header(Color)]
        _ShallowColor ("Shallow Tint", Color) = (0.55, 1.0, 0.93, 1)
        _DeepColor ("Deep Color", Color) = (0.02, 0.33, 0.86, 1)
        _DepthMax ("Depth Fade", Float) = 1.6
        _Clarity ("Clarity", Range(0, 1)) = 0.85

        [Header(Refraction)]
        _Refraction ("Refraction Strength", Range(0, 0.1)) = 0.03

        [Header(Ripples)]
        _RippleScale ("Ripple Scale", Float) = 1.2
        _RippleStrength ("Ripple Strength", Range(0, 2)) = 0.6
        _RippleSpeed ("Ripple Speed", Float) = 0.35

        [Header(Waves)]
        _WaveHeight ("Wave Height", Float) = 0.05
        _WaveLength ("Wave Length", Float) = 6
        _WaveSpeed ("Wave Speed", Float) = 0.8

        [Header(Caustics)]
        _CausticColor ("Caustic Color", Color) = (1, 1, 0.95, 1)
        _CausticIntensity ("Caustic Intensity", Range(0, 3)) = 0.9
        _CausticScale ("Caustic Scale", Float) = 0.9
        _CausticSpeed ("Caustic Speed", Float) = 0.4
        _CausticWidth ("Caustic Softness", Range(0.05, 0.5)) = 0.22
        _CausticSplit ("Caustic Color Split", Range(0, 0.1)) = 0.025
        _CausticDepth ("Caustic Fade Depth", Float) = 3

        [Header(Reflection and Sun)]
        _ReflectionColor ("Sky Tint", Color) = (0.55, 0.85, 1, 1)
        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 0.6
        _FresnelPower ("Fresnel Power", Float) = 5
        _SpecPower ("Sun Highlight Power", Float) = 180
        _SpecIntensity ("Sun Highlight Intensity", Float) = 1.0
        _GlintScale ("Glint Scale", Float) = 6
        _GlintThreshold ("Glint Threshold", Range(0.9, 1)) = 0.995
        _GlintIntensity ("Glint Intensity", Float) = 2
        _DetailFade ("Detail Fade Distance", Float) = 60

        [Header(Shore Foam)]
        _FoamColor ("Foam Color", Color) = (1, 1, 1, 0.9)
        _FoamWidth ("Foam Width", Float) = 0.12
        _FoamSoftness ("Foam Softness", Float) = 0.06
        _FoamNoise ("Foam Edge Noise", Range(0, 1)) = 0.6
        _WetBand ("Light Shore Band", Float) = 0.5

        [Header(Shadow)]
        _ShadowStrength ("Shadow Strength", Range(0, 1)) = 0.3
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" "IgnoreProjector" = "True" }

        Pass
        {
            Name "ChibiWater"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _ShallowColor, _DeepColor;
                float _DepthMax, _Clarity, _Refraction;
                float _RippleScale, _RippleStrength, _RippleSpeed;
                float _WaveHeight, _WaveLength, _WaveSpeed;
                half4 _CausticColor;
                float _CausticIntensity, _CausticScale, _CausticSpeed, _CausticWidth, _CausticSplit, _CausticDepth;
                half4 _ReflectionColor;
                float _ReflectionStrength, _FresnelPower, _SpecPower, _SpecIntensity;
                float _GlintScale, _GlintThreshold, _GlintIntensity, _DetailFade;
                half4 _FoamColor;
                float _FoamWidth, _FoamSoftness, _FoamNoise, _WetBand;
                float _ShadowStrength;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 baseXZ : TEXCOORD1;     // undisplaced world xz
                float fogFactor : TEXCOORD2;
            };

            // ---------- noise
            float2 hash22(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            float valueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                float a = hash22(i).x;
                float b = hash22(i + float2(1, 0)).x;
                float c = hash22(i + float2(0, 1)).x;
                float d = hash22(i + float2(1, 1)).x;
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            // slope of a noise height field (finite differences)
            float2 noiseSlope(float2 p)
            {
                const float e = 0.08;
                float h = valueNoise(p);
                return float2(valueNoise(p + float2(e, 0)) - h, valueNoise(p + float2(0, e)) - h) / e;
            }

            // distance to the nearest cell border
            float cellEdge(float2 p, float t)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float f1 = 8.0, f2 = 8.0;
                [unroll] for (int y = -1; y <= 1; y++)
                [unroll] for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 o = 0.5 + 0.4 * sin(t + 6.2831 * hash22(i + g));
                    float d = length(g + o - f);
                    if (d < f1) { f2 = f1; f1 = d; }
                    else if (d < f2) { f2 = d; }
                }
                return f2 - f1;
            }

            // soft, broken caustic light (two warped layers, brightest where they cross)
            float caustic(float2 p, float t)
            {
                float2 warp = float2(valueNoise(p * 0.6 + t * 0.15), valueNoise(p * 0.6 + 5.2 - t * 0.15)) - 0.5;
                p += warp * 0.9;
                float a = 1.0 - smoothstep(0.0, _CausticWidth, cellEdge(p + float2(0.1, 0.05) * t, t));
                float b = 1.0 - smoothstep(0.0, _CausticWidth, cellEdge(p * 1.3 + float2(-0.07, 0.11) * t + 3.1, t * 1.2));
                float c = a * b * 1.6 + (a + b) * 0.2;
                // large patches of light and shade
                float mask = smoothstep(0.25, 0.75, valueNoise(p * 0.25 + t * 0.05));
                return saturate(c) * (0.35 + 0.65 * mask);
            }

            // ---------- gentle vertex waves: x = height, yz = slope
            float3 waveOne(float2 xz, float2 dir, float len, float amp, float speed)
            {
                float k = 6.2831 / max(len, 0.01);
                float f = k * dot(dir, xz) - speed * _Time.y;
                return float3(sin(f) * amp, cos(f) * amp * k * dir.x, cos(f) * amp * k * dir.y);
            }

            float3 waves(float2 xz)
            {
                float3 w = waveOne(xz, float2(0.83, 0.55), _WaveLength, _WaveHeight, _WaveSpeed);
                w += waveOne(xz, float2(-0.5, 0.86), _WaveLength * 0.6, _WaveHeight * 0.5, _WaveSpeed * 1.3);
                return w;
            }

            Varyings vert(Attributes v)
            {
                Varyings o;
                float3 ws = TransformObjectToWorld(v.positionOS.xyz);
                o.baseXZ = ws.xz;
                ws.y += waves(ws.xz).x;
                o.positionWS = ws;
                o.positionCS = TransformWorldToHClip(ws);
                o.fogFactor = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float t = _Time.y;
                float2 xz = i.baseXZ;

                // surface normal: waves + two drifting ripple layers
                float3 w = waves(xz);
                float2 rp = xz * _RippleScale;
                float2 s1 = noiseSlope(rp + float2(0.6, 0.2) * t * _RippleSpeed);
                float2 s2 = noiseSlope(rp * 1.9 + float2(-0.3, 0.5) * t * _RippleSpeed + 11.0);
                float2 slope = w.yz + (s1 + s2 * 0.6) * _RippleStrength * 0.25;
                float3 n = normalize(float3(-slope.x, 1.0, -slope.y));
                // finer layer just for sun glints
                float2 sg = noiseSlope(xz * _GlintScale + float2(0.4, -0.3) * t);
                float3 ng = normalize(n + float3(-sg.x, 0.0, -sg.y) * 0.35);

                float3 camToSurf = i.positionWS - _WorldSpaceCameraPos;
                float3 v = normalize(-camToSurf);
                float surfEye = LinearEyeDepth(i.positionCS.z, _ZBufferParams);

                // refraction, skip offsets that land on things in front of the water
                float2 uv0 = GetNormalizedScreenSpaceUV(i.positionCS);
                float eye0 = LinearEyeDepth(SampleSceneDepth(uv0), _ZBufferParams);
                float depth0 = max(eye0 - surfEye, 0.0);
                float2 uv = uv0 + n.xz * _Refraction * saturate(depth0 * 2.0);
                float eye = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams);
                if (eye < surfEye) { uv = uv0; eye = eye0; }
                float depth = max(eye - surfEye, 0.0);
                float3 scene = SampleSceneColor(uv);

                // caustics on the seabed
                float3 seabed = _WorldSpaceCameraPos + camToSurf * (eye / max(surfEye, 0.001));
                float2 cp = seabed.xz * _CausticScale + n.xz * 0.3;
                float ct = t * _CausticSpeed;
                float3 caus = float3(caustic(cp + _CausticSplit, ct), caustic(cp, ct), caustic(cp - _CausticSplit, ct));
                caus *= 1.0 - saturate(depth / max(_CausticDepth, 0.001));

                // light coming through the water
                float3 under = scene * lerp(float3(1, 1, 1), _ShallowColor.rgb, saturate(depth * 3.0));
                // caustic light picks up the seabed color
                under += caus * _CausticColor.rgb * _CausticIntensity * (scene * 0.7 + 0.3) * saturate(depth * 4.0);
                float absorb = 1.0 - exp(-depth / max(_DepthMax, 0.001));
                absorb = saturate(absorb * (1.5 - _Clarity));
                float3 col = lerp(under, _DeepColor.rgb, absorb);

                // lighter turquoise band along the shore
                float wet = 1.0 - smoothstep(0.0, max(_WetBand, 0.001), depth);
                col = lerp(col, col * 0.6 + _ShallowColor.rgb * 0.5, wet * 0.35);

                // sun and shadow
                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                col *= lerp(1.0, light.shadowAttenuation, _ShadowStrength);

                // sky reflection
                float fres = pow(1.0 - saturate(dot(n, v)), _FresnelPower);
                float3 refl = GlossyEnvironmentReflection(reflect(-v, n), 0.05, 1.0) * _ReflectionColor.rgb;
                col = lerp(col, refl, fres * _ReflectionStrength);

                // sun highlight and sparkly glints
                float3 h = normalize(light.direction + v);
                float spec = pow(saturate(dot(n, h)), _SpecPower) * _SpecIntensity;
                float detail = 1.0 - smoothstep(_DetailFade * 0.3, _DetailFade, surfEye);   // less sparkle noise far away
                float glint = smoothstep(_GlintThreshold, _GlintThreshold + 0.002, dot(ng, h)) * _GlintIntensity * detail;
                col += light.color * (spec + glint) * light.shadowAttenuation;

                // thin shore foam line with a soft wobbly edge
                float fn = valueNoise(xz * 3.0 + t * 0.2) * 0.6 + valueNoise(xz * 7.0 - t * 0.3) * 0.4;
                float fw = _FoamWidth * (1.0 + (fn - 0.5) * 2.0 * _FoamNoise);
                float foam = 1.0 - smoothstep(fw, fw + _FoamSoftness, depth);
                col = lerp(col, _FoamColor.rgb, foam * _FoamColor.a);

                col = MixFog(col, i.fogFactor);
                return half4(col, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
