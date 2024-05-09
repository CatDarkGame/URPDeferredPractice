#ifndef CUSTOMDEFERRED_LIT_INPUT_INCLUDE
#define CUSTOMDEFERRED_LIT_INPUT_INCLUDE


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);



#endif