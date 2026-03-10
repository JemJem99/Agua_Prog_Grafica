Shader "Tecnocampus/TerrainShader"
{
	Properties
	{
		_HeightmapTex("Heightmap texture", 2D) = "defaulttexture" {}
		_HeatmapTex("Heatmp texture", 2D) = "defaulttexture" {}
		_MaxHeight("_MaxHeight", float) = 80.0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex MyVS
			#pragma fragment MyPS

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 UV : TEXCOORD0;
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 UV : TEXCOORD0;
			};

			sampler2D _HeightmapTex;
			sampler2D _HeatmapTex;
			float _MaxHeight;

			v2f MyVS(appdata v)
			{
				v2f o;

				float l_HeightNormalized = tex2Dlod(_HeightmapTex, float4(v.UV, 0, 0)).x;
				float l_Height = l_HeightNormalized *_MaxHeight;

				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				o.vertex.y += l_Height;
				o.vertex = mul(UNITY_MATRIX_V, o.vertex);
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);
				o.UV = float2(0.5, l_HeightNormalized);
				return o;
			}

			fixed4 MyPS(v2f i) : SV_Target
			{
				float4 l_Color = tex2D(_HeatmapTex, i.UV);
				return l_Color;
			}
			ENDCG
		}
	}
}
