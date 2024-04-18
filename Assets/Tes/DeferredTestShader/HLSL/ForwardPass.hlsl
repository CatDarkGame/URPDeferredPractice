#ifndef DEFERREDTEST_FORWARDPASS_INCLUDED
#define DEFERREDTEST_FORWARDPASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


struct Attributes
{
    float4 positionOS    : POSITION;
    float2 uv            : TEXCOORD0;
    float3 normalOS : NORMAL;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4  positionCS    : SV_POSITION;
    float2  uv            : TEXCOORD0;
    float3  normalWS      : TEXCOORD1;
    half3   vertexSH      : TEXCOORD2;

    UNITY_VERTEX_OUTPUT_STEREO
};


Varyings ForwardPassVertex(Attributes input)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    
    Varyings output = (Varyings)0;
    float4 positionOS = input.positionOS;
    float3 positionWS = TransformObjectToWorld(positionOS.xyz);
    float4 positionCS = TransformWorldToHClip(positionWS);
    output.positionCS = positionCS;

    float3 normalOS = input.normalOS;
    float3 normalWS = TransformObjectToWorldNormal(normalOS);
    output.normalWS = NormalizeNormalPerVertex(normalWS);

    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
  
    float2 uv = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
    output.uv = uv;
   
    return output;
}

void ForwardPassFragment
(
    Varyings input, 
    out half4 outColor : SV_Target0
    #ifdef _WRITE_RENDERING_LAYERS
        , out float4 outRenderingLayers : SV_Target1
    #endif
)
{
    UNITY_SETUP_INSTANCE_ID(input);
  
    half2 uv = input.uv;
    float3 normalWS = NormalizeNormalPerPixel(input.normalWS);
    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half3 color = texColor.rgb * _BaseColor.rgb;
    half alpha = texColor.a * _BaseColor.a;
    
    Light light = GetMainLight();
    half NdotL = saturate(dot(normalWS, light.direction));
    half3 globalIllumination = input.vertexSH;

    half4 finalColor = 1.0h;
    finalColor.rgb = (color * NdotL * light.color) + globalIllumination;
    finalColor.a = alpha;

    outColor = finalColor;

#ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
#endif
}


#endif