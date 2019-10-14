Shader "cova/UI/kadomaru_UI"
{
	Properties
	{
		_Radius("Radius", Range(0,0.5)) = 0.1   // 角丸の円の半径. Width/height の小さい方に対する割合
		_Width("Width", int) = 256              // 使用するシーンでのテクスチャ幅(UnityWhiteを使う場合はRectTrans の width)
		_Height("Height", int) = 256            // 使用するシーンでのテクスチャ高(UnityWhiteを使う場合はRectTrans の height)

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
			float4  _MainTex_TexelSize;
			float   _Radius;
            int _Width;
            int _Height;

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

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				half4 orig = tex2D(_MainTex, i.uv) * i.color;                
                float r = min(_Width, _Height) * _Radius;
                float2 XY = float2(i.uv.x * _Width, i.uv.y * _Height);

                // Calc Distance from each center of circle
                // LeftTop, Center:( r, r)
                float d_lt = (XY.x - r) * (XY.x - r) + (XY.y-r) * (XY.y-r);
                // LeftBot, Center:( r, h-r)
                float d_lb = (XY.x - r) * (XY.x - r) + (XY.y- (_Height - r)) * (XY.y- (_Height - r));
                // RightTop, Center:( w-r, r)
                float d_rt = (XY.x - (_Width-r)) * (XY.x - (_Width - r)) + (XY.y-r) * (XY.y-r);
                // RightBot, Center:( w-r, h-r)
                float d_rb = (XY.x - (_Width-r)) * (XY.x - (_Width - r)) + (XY.y- (_Height - r)) * (XY.y- (_Height - r));

                //
                // The code which is implemented present the code which is comment outed.
                // 以下のコードは下記if 文を表現するためlerp などを用いて実装しています
                //
                // if( r < u < 1-r || r < v < 1-r)
                // {
                //     ret = original;
                // }
                // else
                // {
                //     if( u < 0.5 )
                //     {
                //         if( v > 0.5)
                //         {
                //             ret = D_lb > r ? alpha : orig;
                //         }
                //         else
                //         {
                //             ret = D_lt > r ? alpha : orig;
                //         }
                //     }
                //     else
                //     {
                //         if( v > 0.5)
                //         {
                //             ret = D_rb > r ? alpha : orig;
                //         }
                //         else
                //         {
                //             ret = D_rt > r ? alpha : orig;
                //         }
                //     }
                // }
                

                float isNotCorner = 
                    Is( IsSmaller( r,XY.x ) + IsSmaller(XY.x, (_Width - r))-1 ) // r < x < 1-r
                    + Is( IsSmaller( r, XY.y) + IsSmaller(XY.y, (_Height - r))-1 ); // r < y < 1-r
                
                float left = lerp(
                    lerp(1, 0, Is(d_lt -r*r )),
                    lerp(1, 0, Is(d_lb -r*r )),
                     Is( i.uv.y> 0.5)
                );
                float right = lerp(
                    lerp(1, 0, Is(d_rt -r*r )),
                    lerp(1, 0, Is(d_rb -r*r )),
                    Is( i.uv.y> 0.5)
                );
                float a = lerp( 
                    lerp( left, right, Is( i.uv.x > 0.5)),
                    1,
                    Is(isNotCorner) // r < x < 1-r && r < y < 1-r
                );
                orig.a = a;
                return orig;

			}
			ENDCG
		}
	}
}
