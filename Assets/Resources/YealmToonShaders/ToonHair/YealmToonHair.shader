Shader "YealmToon/Hair"
{
    Properties
    {
        // 剔除设置
        [Header(Base Setting)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("剔除模式", Float) = 0
        [Toggle(_ALPHA_CLIP)] _AlphaTest ("透明度测试", float) = 0

        [Header(general setting)]
        [NoScaleOffset] _BaseMap("BaseMap", 2D) = "white" {}
        _BaseColor("baseColor", Color) = (1,1,1,1)
        [NoScaleOffset] _RampLightingMap("RampLightingMap", 2D) = "white" {}

        _NormalScale("normal scale", Float) = 1.0
        [NoScaleOffset]_NormalMap ("normal", 2D) = "bump" {}

        [Header(highLight)]
        [NoScaleOffset] _SpecularMap("SpecularMap", 2D) = "white" {}
        [HDR]_SpecularColor("specularColor", Color) = (1,1,1,1)
        _SpecularSize("specular区域范围", Range(0, 1)) = 0
        _SpecularSmooth("specular柔和度", Range(0, 1)) = 0

        [Header(Rim Light)]
        [HDR]_RimLightColor("边缘光颜色", Color) = (1,1,1,1)
        _RimLightStrength("边缘光强度", Range(0, 1)) = 0
        _RimLightAlign("边缘光偏移", Range(-1, 1)) = 0
        _RimLightSmoothness("边缘光柔和度", Range(0, 1)) = 0

        [Header(Outline)]
        _OutlineWidth("描边宽度", Range(0, 10)) = 1
        _OutlineColor("描边颜色", Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }


        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // -------------------------------------
            // Render State Commands
            // Use same blending / depth states as Standard shader
            ZWrite On
            Cull Back
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertexCommon
            #pragma fragment LitPassFragmentCommon

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS // 删除了级联阴影 _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS // 删除了顶点光照 _ADDITIONAL_LIGHTS_VERTEX forward+本来也不能用这个
            // #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            // #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            // #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            // #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH

            // #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // ---------------------------------
            // 自定义toggle


            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            
            // input; m66-2 library; pass
            #include "ToonHairLitInput.hlsl"
            #include "ToonHairLitForwardPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma shader_feature_local _ _ALPHA_CLIP

            // -------------------------------------
            // Includes
            #include "ToonHairLitInput.hlsl"
            #include "ToonHairLitShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            
            #pragma shader_feature_local _ _ALPHA_CLIP

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // defines
            #define ToonShaderIsOutline

            // -------------------------------------
            // Includes
            #include "ToonHairLitInput.hlsl"
            #include "ToonHairLitDepthPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ToonOutline"
            Tags
            {
                "LightMode" = "ToonOutline"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull Front

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertexCommon
            #pragma fragment LitPassFragmentCommon

            // -------------------------------------
            // Material Keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            // defines
            #define ToonShaderIsOutline

            // -------------------------------------
            // Includes
            #include "ToonHairLitInput.hlsl"
            #include "ToonHairLitForwardPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "YealmToonMaterialPass"
            Tags
            {
                "LightMode" = "YealmToonMaterialPass"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            Cull Back
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex MaterialPassVertex 
            #pragma fragment MaterialPassFragment 

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            
            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            //#pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // -------------------------------------
            // Includes
            #include "ToonHairLitInput.hlsl"
            #include "ToonHairLitMaterialPass.hlsl"
            ENDHLSL
        }
    }

}