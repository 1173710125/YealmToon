Shader "YealmToon/Eye"
{
    Properties
    {
        // 剔除设置
        [Header(Base Setting)]
        [Toggle(_ALPHA_CLIP)] _AlphaTest ("透明度测试", float) = 0

        [Header(Base Color)]
        [NoScaleOffset] _BaseMap("BaseMap", 2D) = "white" {}
        _BaseColor("baseColor", Color) = (1,1,1,1)
        _ShadowTint("shadowTint", Color) = (0.5,0.5,0.5,1)


        [Header(Highlights)]
        [Toggle(_EYE_HIGHLIGHT)] _EyeHighlight ("开启眼睛高光", float) = 0
        [NoScaleOffset] _HighlightMap("HighlightMap", 2D) = "white" {}
        [HDR]_HighlightColorTint("HighlightColorTint", Color) = (1,1,1,1)
        _HighlightDarken ("HighlightDarken", Range(0, 1)) = 0.1

        [Header(MatCap Reflection)]
        [Toggle(_MATCAP_REFLECTION)] _MatcapReflection ("开启眼睛matcap", float) = 0
        [NoScaleOffset] _MatcapReflectionMap("MatcapReflectionMap", 2D) = "white" {}
        _MatcapReflectionStrength ("MatcapReflectionStrength", Range(0, 2)) = 0
        [NoScaleOffset] _MatcapNormalMap("MatcapNormalMap", 2D) = "white" {}
        _MatcapNormalScale ("MatcapNormalScale", Range(0, 2)) = 1


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
            #pragma vertex LitPassVertexEye
            #pragma fragment LitPassFragmentEye

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

            // ---------------------------------------
            // 自定义变体
            #pragma multi_compile _ _EYE_HIGHLIGHT
            #pragma multi_compile _ _MATCAP_REFLECTION

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
            #include "ToonEyeLitInput.hlsl"
            #include "ToonEyeLitForwardPass.hlsl"

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
            #include "ToonEyeLitInput.hlsl"
            #include "ToonEyeLitShadowCasterPass.hlsl"
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
            #include "ToonEyeLitInput.hlsl"
            #include "ToonEyeLitDepthPass.hlsl"
            ENDHLSL
        }
    }

}
