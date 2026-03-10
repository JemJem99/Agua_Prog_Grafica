Shader "Tecnocampus/Skybox"
{    
    Properties
    {
        _CubeTex ("_CubeTex", Cube) = "defaulttexture" {}
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
            sampler2D _MainTex;
            float4 _MainTex_ST;
            samplerCUBE _CubeTex;
            float _MainSlider;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 Direction : NORMAL;
            };



            v2f vert (appdata v)
             {
                v2f o;


                float3 l_Direction = normalize(v.vertex);
                o.vertex=float4(_WorldSpaceCameraPos-l_Direction*_ProjectionParams.z*0.95, 1.0);
                o.vertex=mul(UNITY_MATRIX_V, o.vertex);
                o.vertex=mul(UNITY_MATRIX_P, o.vertex);
                o.Direction = l_Direction;
                return o;
             }

             
            fixed4 frag (v2f i) : SV_Target
            {

                float3 l_Direction = normalize(i.Direction);
               
                return texCUBE(_CubeTex, -l_Direction);
            }
            ENDCG
        }
    }
}
