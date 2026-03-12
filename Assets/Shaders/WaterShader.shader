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
        _FoamDistance ("_FoamDistance", Range(0.00,1.00)) = 0.5
        _NoiseDirection ("_NoiseDirection", Vector) = (0, 0, 0, 0)
        _FoamDirection ("_FoamDirection", Vector) = (0, 0, 0, 0)
        _NoiseSpeed ("_NoiseSpeed", Float) = 0
        _NoiseTile ("_NoiseTile", Float) = 0
        _NoiseCutOff ("_NoiseCutOff", Range(0.00,1.00)) = 0.5
        _FoamTile ("_FoamTile", Float) = 0
        _FoamSpeed ("_FoamSpeed", Float) = 0

        _CubeTex ("_CubeTex", Cube) = "defaulttexture" {}
        _ReflectionStrength ("_ReflectionStrength", Range(0.0, 1.0)) = 0.3

        _CausticsScale    ("Caustics Scale",    Float)      = 8.0
        _CausticsSpeed    ("Caustics Speed",    Float)      = 0.1
        _CausticsStrength ("Caustics Strength", Range(0,1)) = 0.4
        _CausticsColor    ("Caustics Color",    Color)      = (0.4, 0.8, 1.0, 1.0)

        [Toggle] _DebugCaustics ("Debug Caustics",  Float) = 0
        [Toggle] _DebugFoam     ("Debug Foam",      Float) = 0
        [Toggle] _DebugDepth    ("Debug Depth",     Float) = 0
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
            samplerCUBE _CubeTex;
            float _ReflectionStrength;

            float _CausticsScale;
            float _CausticsSpeed;
            float _CausticsStrength;
            float4 _CausticsColor;
            float _DebugCaustics;
            float _DebugFoam;
            float _DebugDepth;
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
                float3 normal : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

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

            float2 VoronoiHash(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)),
                           dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453);
            }

            float Voronoi(float2 uv)
            {
                float2 cell = floor(uv);
                float2 frac_uv = frac(uv);
                float minDist = 1.0;

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 neighbor = float2(x, y);
                        float2 punto = VoronoiHash(cell + neighbor);
                        punto = 0.5 + 0.5 * sin(_Time.y * 0.3 + 6.2831 * punto);
                        float2 diff = neighbor + punto - frac_uv;
                        minDist = min(minDist, length(diff));
                    }
                }
                return minDist;
            }

            float CalcCaustics(float2 uv)
            {
                float2 uvA = uv*_CausticsScale + float2(_Time.y,  _Time.y * 0.7)*_CausticsSpeed;
                float2 uvB =uv*_CausticsScale + float2(-_Time.y, -_Time.y * 0.5)*_CausticsSpeed;

                float vA = Voronoi(uvA);
                float vB = Voronoi(uvB);

                float caustic = 1.0 - min(vA, vB);
                caustic = pow(caustic, 3.0);
                return caustic;
            }

            v2f MyVS(appdata v)
            {
                v2f o;

                o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
                o.worldPos = o.vertex.xyz;

                float2 noiseUV = v.UV*_NoiseTile + _NoiseDirection.xy*_NoiseSpeed;
                _Noise = tex2Dlod(_NoiseTex, float4(noiseUV, 0, 0)).r;
                float2 baseUV = v.UV + _Noise;

                float eps = 0.1;
                float l_Height = CalcHeight(baseUV, float2(0, 0));
                float hX = CalcHeight(baseUV, float2(eps, 0));
                float hZ = CalcHeight(baseUV, float2(0, eps));

                o.vertex.y += l_Height;
                o.worldPos.y += l_Height;

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
                float4 l_WaterTexColor = tex2D(_WaterTex, i.UV);
                float2 uvNoise = i.UV*_NoiseTile + _NoiseDirection.xy*_Time.y*_NoiseSpeed;
                float2 noiseOffset = tex2D(_NoiseTex, uvNoise).rg * 2.0 - 1.0;

                float2 l_UVFoam = i.UVFoam + _FoamDirection.xy*_Time.y*_FoamSpeed + noiseOffset*0.05;

                if (l_WaterDepthTexColor < _FoamDistance)
                {
                    if (!_DebugFoam)
                    {
                        float4 l_FoamColor = tex2D(_FoamTex, l_UVFoam);
                        float noiseMask = tex2D(_NoiseTex, uvNoise*0.5).r;
                        float foamAlpha = smoothstep(_NoiseCutOff, _NoiseCutOff + 0.2, noiseMask);
                        _WaterColor = _WaterColor*0.85 + l_FoamColor*0.15;
                    }
                }

                float4 l_WaterColor = lerp(_DeepWaterColor, _WaterColor, l_WaterDepthTexColor);

                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(i.worldPos - _WorldSpaceCameraPos);
                float3 reflected = reflect(viewDir, normal);
                float4 skyColor = texCUBE(_CubeTex, reflected);

                float causticValue = CalcCaustics(i.UV);
                float depthMask = smoothstep(0.4, 0.0, l_WaterDepthTexColor);
                causticValue *= depthMask;

                if (_DebugCaustics) return float4(causticValue.xxx, 1.0);
                if (_DebugDepth)    return float4(l_WaterDepthTexColor.xxx, 1.0);
                if (_DebugColor)    return float4(l_WaterColor.rgb, 1.0);

                float3 finalColor = l_WaterColor.rgb * 0.8 + l_WaterTexColor.rgb * 0.2;
                finalColor = lerp(finalColor, skyColor.rgb, _ReflectionStrength);

                float3 causticsContrib = _CausticsColor.rgb*causticValue*_CausticsStrength;
                finalColor = 1.0 - (1.0 - finalColor)*(1.0 - causticsContrib);

                return float4(finalColor, 0.9);
            }
            ENDCG
        }
    }
}