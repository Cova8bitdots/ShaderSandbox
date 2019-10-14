Shader "cova/UI/parallelogram"
{
	Properties
	{
		_Ratio("Ratio", Range(0.001,0.999)) = 0.5   // 長辺に対する割合
        [MaterialToggle] _IsNegative ("右肩下がり?", Float) = 0

		[PerRendererData]
         _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)

		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil
		{
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		LOD 0

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"



			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
			};

			sampler2D _MainTex;
			float4  _MainTex_ST;
			float   _Ratio;
            float _IsNegative;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}


			// 負数:0, 正数:1 に変換
            // 条件を見たしているかどうかチェック
			float Is(float _value) { return ceil(saturate(_value)); }

            // a がb よりも小さいかどうか
            float IsSmaller(float a, float b){ return Is( b - a); }
            // a がb よりも大きいかどうか
            float IsBig(float a, float b){ return Is( a-b ); }

            float CalcLinearFunc( float x, float x_offset, float a, float b)
            {
                return a * ( x - x_offset) + b;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				half4 orig = tex2D(_MainTex, i.uv) * i.color;

                // y = -h/r*x + h < v < y = -h/r*( x - (1-r)) + h -> draw
                float a_neg = Is(
                    IsBig(i.uv.y, CalcLinearFunc(i.uv.x, 0, -1.0/_Ratio, 1.0) )
                    + IsSmaller(i.uv.y, CalcLinearFunc(i.uv.x, 1.0-_Ratio, -1.0/_Ratio, 1.0))
                    -1
                );

                // y = -h/r*x  < v < y = h/r*x - h/r*(1-r) -> draw
                float a_pos = Is( 
                    IsSmaller(i.uv.y, CalcLinearFunc(i.uv.x, 0.0, 1.0/_Ratio, 0.0) )
                    + IsBig(i.uv.y, CalcLinearFunc(i.uv.x, 0, 1.0/_Ratio, 1.0-1.0/_Ratio  ) )
                    -1
                );

                // 設定に応じて適応する値を変更
                orig.a = lerp( a_pos, a_neg, _IsNegative);
                return orig;

			}
			ENDCG
		}
	}
}
