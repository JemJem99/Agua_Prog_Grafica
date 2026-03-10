Shader "Tecnocampus/WaterShader"
{
	Properties
	{	
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

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
			};
			

			v2f MyVS(appdata v)
			{
				v2f o;
				
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				o.vertex = mul(UNITY_MATRIX_V, o.vertex);
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);
				return o;
			}

			fixed4 MyPS(v2f i) : SV_Target
			{
				return float4(0,0,1, 0.6);
			}
			ENDCG
		}
	}
}
