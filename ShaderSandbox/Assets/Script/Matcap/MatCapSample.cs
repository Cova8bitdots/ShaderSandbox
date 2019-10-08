using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace cova.tech.sandbox.shader
{
	public class MatCapSample : MonoBehaviour
	{
		[SerializeField]
		Material TargetMaterial = null;
	
	
		private void OnRenderImage(RenderTexture src, RenderTexture dest)
		{
			Graphics.Blit( src, dest, TargetMaterial );
		}
	}

}
