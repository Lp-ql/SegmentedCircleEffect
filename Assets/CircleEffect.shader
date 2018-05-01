Shader "Unlit/CircleEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
        _NumSegments ("Segments", Int) = 1
        _NumRings ("Rings", Int) = 1
        _MinRing ("Inner Ring", Int) = 0
        _MaxRing ("Outer Ring", Int) = 0
        _RingBorder ("Ring Border Thickness", Range(0, 1)) = 0
        _SegmentBorder ("Segment Border Thickness", Range(0, 1)) = 0
        _Debug ("Debug", Float) = 0
        _Debug2 ("Debug2", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
            #include "NoiseSimplex.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
            float _Debug;
            float _Debug2;
            float _NumSegments;
            float _NumRings;
            float _MinRing;
            float _MaxRing;
            float _RingBorder;
            float _SegmentBorder;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

            // Returns the ring number and segment number of the region in the circle pattern containing uv
            // x: ring number
            // y: segment number
            // z: ring fraction
            // w: segment fraction
            float4 regionId (float2 uv) {
                float pi = 3.1415927;
                float2 ray = uv - float2(0.5, 0.5);

                float d = length(ray);                // Range: [0, sqrt(2) / 2]
                float d_norm = d * sqrt(2);           // Range: [0, 1]

                float ring = floor(d_norm * _NumRings);
                float ringOffset = fmod(ring, 2) * pi / _NumSegments;
                
                float a = atan2(ray.y, ray.x) + ringOffset;        // Range: [-pi + ringOffset, pi + ringOffset]
                float a_adjusted = atan2(sin(a), cos(a));          // Range: [-pi, pi]
                float a_norm = (a_adjusted + pi) / (2 * pi);       // Range: [0, 1]
                
                float segment = floor(a_norm * _NumSegments);

                float ring_frac = frac(d_norm * _NumRings);
                float segment_frac = frac(a_norm * _NumSegments);

                return float4(ring, segment, ring_frac, segment_frac);
            }

            // Basic hash function: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
            float rand(float2 co){
                return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453); // Range: [0, 1]
            }
			
			fixed4 frag (v2f i) : SV_Target
			{
                float4 region = regionId(i.uv);

                // Clip out some rings
                clip(_MaxRing - region.x);
                clip(region.x - _MinRing);

                // Clip out the borders
                clip(region.z - _RingBorder);
                clip(region.w - _SegmentBorder);
                
                // Visualize regions
                //int regionId = region.x * _NumSegments + region.y;
				//fixed4 col = fixed4(regionId / (_NumSegments * _NumRings), 0, 0, 1);
				//return col;

                return fixed4(1, 1, 1, snoise(region.xy + _Time.x * 10));
			}
			
            ENDCG
		}
	}
}
