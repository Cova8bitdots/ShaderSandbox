// http://esprog.hatenablog.com/entry/2017/01/28/231735
// を参考に作成

Shader "Custom/SimpleMatcapShader"
{
	Properties
	{
		_MainTex ("BaseTexture", 2D) = "white" {}
		_MatCap ("MatCap Tex", 2D) = "white"{}
		_Range("Range", Range(0,1.5)) = 0.5
		_BlendRate("Blend Rate", Range(0,1)) = 0.5

	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 normal : TEXCOORD1;
			};

			sampler2D	_MainTex;
			sampler2D	_MatCap;
			float		_Range;
			float		_BlendRate;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = normalize( float4(v.normal, 1));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 baseCol = tex2D( _MainTex, i.uv);
				// float2 normalVec = i.normal.xyz * 0.5 + 0.5;
				float2 normalVec = i.normal.xyz;
				fixed4 mapCapCol = tex2D( _MatCap, normalVec * _Range );
				fixed4 col = lerp(baseCol, mapCapCol, _BlendRate );

				return col;
			}
			ENDCG
		}
	}
}
