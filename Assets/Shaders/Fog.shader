Shader "Unlit/Fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogDensity ("_FogDensity", Float) = 0
        _FogStartLinearDistance ("_FogStartLinearDistance", Float) = 0
        _FogEndLinearDistance ("_FogEndLinearDistance", Float) = 100
        _FogColor ("Fog Color", Color) = (0.5, 0.5, 0.5, 1)
        [KeywordEnum (Linear, Exp, Exp2)] _FogType ("_FogType", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #pragma shader_feature _FOGTYPE_LINEAR _FOGTYPE_EXP _FOGTYPE_EXP2
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _FogDensity;
            float _FogStartLinearDistance;
            float _FogEndLinearDistance;
            float4 _FogColor;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float l_Depth = length(i.worldPos - _WorldSpaceCameraPos.xyz);

                #ifdef _FOGTYPE_LINEAR
                        float l_FogIntensity = saturate((l_Depth - _FogStartLinearDistance) / (_FogEndLinearDistance - _FogStartLinearDistance));


                #elif _FOGTYPE_EXP
                        float l_FogIntensity = 1.0-(1.0/exp(l_Depth*_FogDensity));

                #else
                        float l_FogIntensity = 1.0-(1.0/exp(l_Depth*_FogDensity*l_Depth*_FogDensity));

                #endif


                float4 l_MainTexColor = tex2D(_MainTex, i.uv);
                
                
                return float4(l_MainTexColor.xyz * (1.0 - l_FogIntensity) + l_FogIntensity * _FogColor.xyz, 1);
            }
            ENDCG
        }
    }
}