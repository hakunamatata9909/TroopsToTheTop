Shader "Hidden/WeightPainterRG/Overlay"
{
    Properties
    {
        _ChannelMask ("Channel Mask", Vector) = (1,0,0,0)
        _Opacity ("Opacity", Range(0,1)) = 0.5
        _WireframeOpacity ("Wireframe Opacity", Range(0,1)) = 0.2
        _BaseColor ("Base Color", Color) = (0,0,0,0)
    }
    SubShader
    {
        // Render after regular transparent objects to appear on top
        Tags { "Queue"="Transparent+10" "RenderType"="Transparent" "IgnoreProjector"="True" }
        
        // --- RENDER STATE CONFIGURATION ---
        Cull Back       // Hide backfaces to avoid visual clutter
        ZTest LEqual    // Standard depth test: visible only if not occluded by geometry in front
        ZWrite Off      // Do not write to Z-buffer (so we don't block other gizmos)
        Offset -1, -1   // Pull the overlay slightly towards camera to prevent Z-Fighting
        Blend SrcAlpha OneMinusSrcAlpha 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };

            struct v2g {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            struct g2f {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
                float3 bary : TEXCOORD0; // Barycentric coordinates for wireframe calculation
            };

            float4 _ChannelMask;
            float _Opacity;
            float _WireframeOpacity;

            // --- VERTEX SHADER ---
            v2g vert (appdata v) {
                v2g o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                return o;
            }

            // --- GEOMETRY SHADER ---
            // This generates the wireframe data on the fly
            [maxvertexcount(3)]
            void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
                g2f o;
                
                // Assign barycentric coordinates to the triangle vertices:
                // (1,0,0), (0,1,0), (0,0,1).
                // The pixel shader uses this to determine how close a pixel is to an edge.
                
                o.vertex = IN[0].vertex; o.color = IN[0].color; o.bary = float3(1, 0, 0); triStream.Append(o);
                o.vertex = IN[1].vertex; o.color = IN[1].color; o.bary = float3(0, 1, 0); triStream.Append(o);
                o.vertex = IN[2].vertex; o.color = IN[2].color; o.bary = float3(0, 0, 1); triStream.Append(o);
            }

            // --- FRAGMENT SHADER ---
            fixed4 frag (g2f i) : SV_Target {
                // 1. Calculate Weight Intensity
                // Dot product extracts the specific channel value (e.g., Red)
                float value = dot(i.color, _ChannelMask);
                
                // Determine display color (R->Red, G->Green, etc.)
                float3 targetColor = _ChannelMask.rgb + float3(1,1,1) * _ChannelMask.a;
                
                // Debug fallback: if multiple channels selected, show raw RGB
                if(length(_ChannelMask) > 1.1) targetColor = i.color.rgb;

                // 2. Calculate Wireframe
                // Find distance to the closest edge
                float minBary = min(i.bary.x, min(i.bary.y, i.bary.z));
                
                // Use fwidth for consistent line width regardless of distance
                // or just smoothstep for performance. Here we use smoothstep for soft lines.
                // 0.03 is the line thickness threshold.
                float wireEdge = 1.0 - smoothstep(0, 0.03, minBary); 
                
                // 3. Mix Final Color
                float3 finalColor = targetColor * value;
                
                // Calculate base alpha based on weight value
                float finalAlpha = (value * 0.8 + 0.1) * _Opacity;

                // Wireframe color (Light Grey)
                float3 wireColor = float3(0.8, 0.8, 0.8); 
                
                // Blend wireframe on top based on edge factor and opacity setting
                finalColor = lerp(finalColor, wireColor, wireEdge * _WireframeOpacity * 2.0);
                
                // Boost alpha where the wireframe is, so lines are visible even on zero-weight areas
                finalAlpha = max(finalAlpha, wireEdge * _WireframeOpacity);

                return fixed4(finalColor, finalAlpha);
            }
            ENDCG
        }
    }
}