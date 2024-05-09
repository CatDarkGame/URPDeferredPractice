Shader "CatDarkGame/CustomDeferredLit"
{
    Properties
    {
        [MainTexture] _BaseMap("Texture", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1, 1, 1, 1)

        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Name "Forward"
            Tags {"LightMode" = "UniversalForward_Block"}

            ZWrite[_ZWrite]
            Cull[_Cull]
           
            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex ForwardPassVertex
            #pragma fragment ForwardPassFragment

            
            #include "HLSL/CustomDeferredLit_Input.hlsl"
            #include "HLSL/CustomDeferredLit_Forward.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "GBuffer"
            Tags {"LightMode" = "CustomGBuffer"}

            ZWrite[_ZWrite]
            Cull[_Cull]
           
            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex GBufferPassVertex
            #pragma fragment GBufferPassFragment

            
            #include "HLSL/CustomDeferredLit_Input.hlsl"
            #include "HLSL/CustomDeferredLit_GBuffer.hlsl"
            ENDHLSL
        }


    }
}
