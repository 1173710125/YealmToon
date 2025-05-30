// Not for redistribution without the author's express written permission
Shader "MMD4Mecanim/MMDLit-NoShadowCasting-BothFaces-Transparent"
{
	Properties
	{
		_Color("Diffuse", Color) = (1,1,1,1)
		_Specular("Specular", Color) = (1,1,1) // Memo: Postfix from material.(Revision>=0)
		_Ambient("Ambient", Color) = (1,1,1)
		_Shininess("Shininess", Float) = 0
		_ShadowLum("ShadowLum", Range(0,10)) = 1.5
		_AmbientToDiffuse("AmbientToDiffuse", Float) = 5
		_EdgeColor("EdgeColor", Color) = (0,0,0,1)
		_EdgeScale("EdgeScale", Range(0,2)) = 0 // Memo: Postfix from material.(Revision>=0)
		_EdgeSize("EdgeSize", float) = 0 // Memo: Postfix from material.(Revision>=0)
		_MainTex("MainTex", 2D) = "white" {}
		_ToonTex("ToonTex", 2D) = "white" {}

		_SphereCube("SphereCube", Cube) = "white" {} // Memo: Postfix from material.(Revision>=0)

		_Emissive("Emissive", Color) = (0,0,0,0)
		_ALPower("ALPower", Float) = 0

		_AddLightToonCen("AddLightToonCen", Float) = -0.1
		_AddLightToonMin("AddLightToonMin", Float) = 0.5

		_ToonTone("ToonTone", Vector) = (1.0, 0.5, 0.5, 0.0) // ToonTone, ToonTone / 2, ToonToneAdd, Unused

		_NoShadowCasting("__NoShadowCasting", Float) = 1.0

		_TessEdgeLength("Tess Edge length", Range(2,50)) = 5
		_TessPhongStrength("Tess Phong Strengh", Range(0,1)) = 0.5
		_TessExtrusionAmount("TessExtrusionAmount", Float) = 0.0

		_Revision("Revision",Float) = -1.0 // Memo: Shader setting trigger.(Reset to 0<=)
	}

	SubShader
	{
		Tags { "Queue" = "Geometry+2" "RenderType" = "Transparent" "ForceNoShadowCasting" = "True" }
		LOD 200

		UsePass "MMD4Mecanim/MMDLit-BothFaces-Transparent/FORWARD"
		UsePass "MMD4Mecanim/MMDLit-BothFaces-Transparent/FORWARD_DELTA"
		UsePass "MMD4Mecanim/MMDLit-BothFaces-Transparent/FORWARD2"
		UsePass "MMD4Mecanim/MMDLit-BothFaces-Transparent/FORWARD_DELTA2"

		Cull Off
		Blend Off
		ColorMask RGBA

		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			Fog {Mode Off}
			ZWrite On ZTest LEqual Cull Off
			Offset 1, 1
			CGPROGRAM
			#pragma target 2.0
			#pragma exclude_renderers flash
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcaster
			#include "MMD4Mecanim-MMDLit-Surface-ShadowCaster.cginc"
			ENDCG
		}

		Pass {
			Name "ShadowCollector"
			Tags { "LightMode" = "ShadowCollector" }
			Fog {Mode Off}
			ZWrite On ZTest LEqual
			CGPROGRAM
			#pragma target 2.0
			#pragma exclude_renderers flash
			#pragma vertex vert_surf
			#pragma fragment frag_surf
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcollector
			#include "MMD4Mecanim-MMDLit-Surface-ShadowCollector.cginc"
			ENDCG
		}
	}

	Fallback Off
	CustomEditor "MMD4MecanimMaterialInspector"
}
