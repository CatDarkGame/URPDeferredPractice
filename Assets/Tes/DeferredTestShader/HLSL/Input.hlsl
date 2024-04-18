#ifndef DEFERREDTEST_INPUT_INCLUDED
#define DEFERREDTEST_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
CBUFFER_END

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);


#endif