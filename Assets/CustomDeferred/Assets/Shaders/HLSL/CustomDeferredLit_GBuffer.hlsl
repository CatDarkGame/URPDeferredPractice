#ifndef CUSTOMDEFERRED_LIT_PASS_GBUFFER_INCLUDE
#define CUSTOMDEFERRED_LIT_PASS_GBUFFER_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS    : POSITION;
    float2 uv            : TEXCOORD0;
    float3 normalOS      : NORMAL;
};

struct Varyings
{
    float4  positionCS    : SV_POSITION;
    float2  uv            : TEXCOORD0;
    float3  normalWS      : TEXCOORD1;
};


Varyings GBufferPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    float4 positionOS = input.positionOS;
    float3 positionWS = TransformObjectToWorld(positionOS.xyz);
    float4 positionCS = TransformWorldToHClip(positionWS);
    output.positionCS = positionCS;

    float3 normalOS = input.normalOS;
    float3 normalWS = TransformObjectToWorldNormal(normalOS);
    output.normalWS = normalWS;

    float2 uv = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
    output.uv = uv;
   
    return output;
}

void GBufferPassFragment(Varyings input, out half4 outColor : SV_Target0)
{
    float2 uv = input.uv;
    float3 normalWS = NormalizeNormalPerPixel(input.normalWS);

    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half3 color = texColor.rgb * _BaseColor.rgb;
    half alpha = texColor.a * _BaseColor.a;
    
    Light light = GetMainLight();
    half NdotL = saturate(dot(normalWS, light.direction));
    half3 globalIllumination = SampleSH(normalWS);

    half4 finalColor = 1.0h;
    finalColor.rgb = (color * NdotL * light.color) + globalIllumination;
    finalColor.a = alpha;

    outColor = finalColor * 0.5f;
}


#endif