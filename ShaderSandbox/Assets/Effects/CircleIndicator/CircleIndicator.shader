Shader "cova/UI/CircleIndicator"
{
    Properties
    {
		_ProcessColor("_ProcessColor", Color) = (1,1,1,1)
		_CompleteColor("_CompleteColor", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_AngleRefTex("AngleRefTex", 2D) = "white" {}
		_Radius("Radius", Range(0,1.0)) = 1.
		_Width("Width", Range(0,1.0)) = 0.2
		_Angle("正規化角度", Range(0,1.0)) = 0.1
		_AngleOffset("角度Offset", Range(0, 1.0)) = 0.0
		_AngleMax("最大正規化角度", Range(0, 1.0)) = 1.0
	}
    SubShader
    {
        Tags
		{
			"Queue"="Transparent"
			"RenderType" = "Transparent"
		}
        LOD 100

		Cull Off
		Lighting Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
        
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

            };

			float4 _ProcessColor;
			float4 _CompleteColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _AngleRefTex;
			float4 _AngleRefTex_ST;
			float		_Radius;
			float		_Width;
			float		_Angle;
			float		_AngleOffset;
			float		_AngleMax;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }


			// 負数:0, 正数:1 に変換
			float GetSign01(float _value) { return ceil(clamp(_value, 0, 1)); }

			// 小数部分のみを返す
			// 負数: v - ceil(v)
			// 正数: v - floor(v)
			float GetMod(float _value){ return lerp(_value - ceil(_value), _value - floor(_value), GetSign01(_value) );}

            fixed4 frag (v2f i) : SV_Target
            {
				// 進行度によって適用する色を変える
				fixed4 mulCol = lerp(_CompleteColor, _ProcessColor, ceil(1-_Angle));
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * mulCol;
				//透過cell
				fixed4 transparentCell = float4(0.0, 0.0, 0.0, 0.0);
			
				// Normalized Position
				float2 xy = float2(i.uv.x * 2.0 - 1.0, i.uv.y*2.0 - 1.0);
				float dist = xy.x* xy.x + xy.y*xy.y;
				float angle = tex2D(_AngleRefTex, i.uv).a;


				float r = _Radius * (1.0f - _Width);
				// dist < r^2 -> transparentCell
				// dist > _Range^2 -> transparentCell
				// theta > _Angle  -> transparentCell
				// どれかでもNGならTransparent
				int v = GetSign01(1 - GetSign01(r*r - dist)- GetSign01(dist - _Radius * _Radius)- GetSign01(GetMod(angle+_AngleOffset) - _Angle* _AngleMax) );
				fixed4 result = lerp(transparentCell, col, v);
                return result;
            }
            ENDCG
        }
    }
}
