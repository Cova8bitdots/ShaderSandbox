Shader "cova/UI/CircleItemIcon"
{
	Properties
	{
		_BgColor("BgColor", Color) = (1,1,1,1)
		_RimColor("RimColor", Color) = (1,1,1,1)
		_Radius("Radius", Range(0,1.0)) = 1.0
		_Width("Width", Range(0,1.0)) = 0.2

		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
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

			float4 _BgColor;
			float4 _RimColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float		_Radius;
			float		_Width;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}


			// 負数:0, 正数:1 に変換
			float GetSign01(float _value) { return ceil(clamp(_value, 0, 1)); }

			// 小数部分のみを返す
			// 負数: v - ceil(v)
			// 正数: v - floor(v)
			float GetMod(float _value) { return lerp(_value - ceil(_value), _value - floor(_value), GetSign01(_value)); }

			fixed4 frag(v2f i) : SV_Target
			{
				// 進行度によって適用する色を変える
				fixed4 baseColor = _BgColor;
				// sample the texture
				half4 col = (tex2D(_MainTex, i.uv) + _BgColor) * i.color;

				//透過cell
				half4 transparentCell = half4(0, 0, 0, 0);

				// Normalized Position
				float2 xy = float2(i.uv.x * 2.0 - 1.0, i.uv.y * 2.0 - 1.0);
				float dist = xy.x * xy.x + xy.y * xy.y;


				float r = _Radius * (1.0f - _Width);
				// dist > _Range^2 -> transparentCell
				//  r^2 < dist <= _Range^2 -> _RimColor
				// dist < r^2 -> tex+baseColor
				//half4 retColor=lerp(  ),
				//	col,
				//	GetSign01(r * r - dist) );
				return lerp(col, lerp(_RimColor, transparentCell, GetSign01(dist - _Radius * _Radius)), GetSign01(dist - r * r));
				//return lerp(_RimColor, transparentCell, GetSign01(dist - _Radius * _Radius));
				//return retColor;
			}
			ENDCG
		}
	}
}
