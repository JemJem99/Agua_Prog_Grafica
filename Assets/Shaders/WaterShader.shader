Shader "Tecnocampus/WaterShader"
{
	Properties
	{	
		_WaterTex ("_WaterTex", 2D) = "" {}
		_WaterDepthTex ("_WaterDepthTex", 2D) = "" {}
		_NoiseTex ("_NoiseTex", 2D) = "" {}
		_FoamTex ("_FoamTex", 2D) = "" {}
		_DeepWaterColor ("_DeepWaterColor", Color) = (0, 0, 0, 0)
		_WaterColor ("_WaterColor", Color) = (0, 0, 0, 0)

		_SpeedWater1 ("_SpeedWater1", Float) = 0
		_DirectionWater1("_DirectionWater1", Vector) = (0, 0, 0, 0)

		_SpeedWater2 ("_SpeedWater2", Float) = 0
		_DirectionWater2("_DirectionWater2", Vector) = (0, 0, 0, 0)

		_SpeedWater3 ("_SpeedWater3", Float) = 0
		_DirectionWater3("_DirectionWater3", Vector) = (0, 0, 0, 0)

		_MaxHeightWater ("_MaxHeightWater", Float) = 0
		_FoamDistance ("_FoamDistance", Range (0.00,1.00)) = 0.5
		_NoiseDirection ("_NoiseDirection", Vector) = (0, 0, 0, 0)
		_FoamDirection ("_FoamDirection", Vector) = (0, 0, 0, 0)
		_NoiseSpeed ("_NoiseSpeed", Float) = 0
		_NoiseTile ("_NoiseTile", Float) = 0
		_NoiseCutOff ("_NoiseCutOff", Range (0.00,1.00)) = 0.5
		_FoamTile ("_FoamTile", Float) = 0
		_FoamSpeed ("_FoamSpeed", Float) = 0

		_CubeTex ("_CubeTex", Cube) = "defaulttexture" {}
		_ReflectionStrength ("_ReflectionStrength", Range(0.0, 1.0)) = 0.3  // [ADDED]

		[Toggle] _DebugFoam     ("Debug Foam",     Float) = 0
		[Toggle] _DebugDepth    ("Debug Depth",    Float) = 0
		[Toggle] _DebugColor    ("Debug Color Only", Float) = 0

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

			sampler2D _WaterTex;
			float4 _WaterTex_ST;
			sampler2D _WaterDepthTex; 
			sampler2D _NoiseTex; 
			float4 _FoamColor; 
			float4 _DeepWaterColor; 
			float4 _WaterColor; 

			float _SpeedWater1;
			float4 _DirectionWater1;

			float _SpeedWater2; 
			float4 _DirectionWater2;

			float _SpeedWater3; 
			float4 _DirectionWater3;

			float _MaxHeightWater; 
			float _FoamDistance; 
			float4 _NoiseDirection; 
			float4 _FoamDirection; 
			float _NoiseSpeed; 
			float _NoiseTile; 
			float _NoiseCutOff; 
			float _FoamTile;
			float _FoamSpeed;
			sampler2D _FoamTex;
			float4 _FoamTex_ST;
			float _Noise;
			samplerCUBE _CubeTex;        // [ADDED]
			float _ReflectionStrength;   // [ADDED]

			float _DebugNormals;
			float _DebugFoam;
			float _DebugDepth;
			float _DebugNoise;
			float _DebugColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 UV : TEXCOORD0;
				float2 UVNoise : TEXCOORD1;
				float2 UVFoam : TEXCOORD2;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 UV : TEXCOORD0;
				float2 UVFoam : TEXCOORD2;
				float3 normal : TEXCOORD3;    // [ADDED]
				float3 worldPos : TEXCOORD4;  // [ADDED]
			};

			// [ADDED] evita repetir la formula de altura 3 veces
			float CalcHeight(float2 baseUV, float2 offset)
			{
				float2 uv1 = baseUV + offset + _DirectionWater1.xy * _Time.y * _SpeedWater1;
				float2 uv2 = baseUV + offset + _DirectionWater2.xy * _Time.y * _SpeedWater2;
				float2 uv3 = baseUV + offset + _DirectionWater3.xy * _Time.y * _SpeedWater3;

				return _MaxHeightWater *
					cos(dot(uv1, _DirectionWater1.xy) * _DirectionWater1.z) +
					cos(dot(uv2, _DirectionWater2.xy) * _DirectionWater2.z) +
					cos(dot(uv3, _DirectionWater3.xy) * _DirectionWater3.z);
			}

			v2f MyVS(appdata v)
			{
				v2f o;
    
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				o.worldPos = o.vertex.xyz;  // [ADDED]

				float2 noiseUV = v.UV * _NoiseTile + _NoiseDirection.xy * _NoiseSpeed;
				_Noise = tex2Dlod(_NoiseTex, float4(noiseUV,0,0)).r;
				float2 baseUV = v.UV + _Noise;

				// [CHANGED] usando CalcHeight para calcular normal sin repetir codigo
				float eps = 0.1;
				float l_Height = CalcHeight(baseUV, float2(0, 0));
				float hX       = CalcHeight(baseUV, float2(eps, 0));
				float hZ       = CalcHeight(baseUV, float2(0, eps));

				o.vertex.y += l_Height;
				o.worldPos.y += l_Height;  // [ADDED]

				// [ADDED] normal perpendicular al gradiente de altura
				float3 normal = normalize(float3(l_Height - hX, eps, l_Height - hZ));
				o.normal = mul((float3x3)unity_ObjectToWorld, normal);

				o.vertex = mul(UNITY_MATRIX_V, o.vertex);
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);
				o.UV = TRANSFORM_TEX(v.UV, _WaterTex);
				o.UVFoam = TRANSFORM_TEX(v.UV, _FoamTex);
				return o;
			}

			fixed4 MyPS(v2f i) : SV_Target
			{
				float l_WaterDepthTexColor = tex2D(_WaterDepthTex, i.UV).r;
				float4 l_WaterTexColor = tex2D(_WaterTex, i.UV);  // [CHANGED] float -> float4
				float2 uvNoise = i.UV * _NoiseTile + _NoiseDirection.xy * _Time.y * _NoiseSpeed;
				float2 noiseOffset = tex2D(_NoiseTex, uvNoise).rg * 2.0 - 1.0; 

				float2 l_UVFoam = i.UVFoam + _FoamDirection.xy * _Time.y * _FoamSpeed + noiseOffset * 0.05;

				if (l_WaterDepthTexColor < _FoamDistance) 
				{
					if (!_DebugFoam)
					{
						float4 l_FoamColor = tex2D(_FoamTex, l_UVFoam);
						float noiseMask = tex2D(_NoiseTex, uvNoise * 0.5).r;
						float foamAlpha = smoothstep(_NoiseCutOff, _NoiseCutOff + 0.2, noiseMask);
						_WaterColor = _WaterColor * 0.85 + l_FoamColor * 0.15;
					}
				}

				float4 l_WaterColor = lerp(_DeepWaterColor, _WaterColor, l_WaterDepthTexColor);

				// [ADDED] reflejo del cubemap
				float3 normal    = normalize(i.normal);
				float3 viewDir   = normalize(i.worldPos - _WorldSpaceCameraPos);
				float3 reflected = reflect(viewDir, normal);
				float4 skyColor  = texCUBE(_CubeTex, reflected);

				if (_DebugDepth) return float4(l_WaterDepthTexColor.xxx, 1.0);
				if (_DebugColor) return float4(l_WaterColor.rgb, 1.0);

				// [CHANGED] mezcla final con reflejo
				float3 finalColor = l_WaterColor.rgb * 0.8 + l_WaterTexColor.rgb * 0.2;
				finalColor = lerp(finalColor, skyColor.rgb, _ReflectionStrength);

				return float4(finalColor, 0.9);
			}
			ENDCG
		}
	}
}