#ifndef DEFERREDTEST_FORWARDPASS_INCLUDED
#define DEFERREDTEST_FORWARDPASS_INCLUDED


#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS               : SV_POSITION;
    float2 uv                       : TEXCOORD0;
#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD1;
#endif
    half3 normalWS                  : TEXCOORD2;
#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    half4 tangentWS                 : TEXCOORD3;    // xyz: tangent, w: sign
#endif
#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS                 : TEXCOORD6;
#endif
    half3 vertexSH : TEXCOORD7;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


Varyings LitGBufferPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
   
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.normalWS = normalInput.normalWS;

    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        real sign = input.tangentOS.w * GetOddNegativeScale();
        half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
    #endif
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
        output.tangentWS = tangentWS;
    #endif

    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
        half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
        output.viewDirTS = viewDirTS;
    #endif

    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
        output.positionWS = vertexInput.positionWS;
    #endif
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        output.shadowCoord = GetShadowCoord(vertexInput);
    #endif

    output.positionCS = vertexInput.positionCS;
    return output;
}


FragmentOutput InitializeGbufferData(float4 positionCS, float3 normalWS, half3 albedo, half3 specular, half smoothness, half reflectivity, half occlusion, half3 globalIllumination)
{
    half3 packedNormalWS = PackNormal(normalWS);

    // material Flags
    uint materialFlags = 0;
    #ifdef _RECEIVE_SHADOWS_OFF
        materialFlags |= kMaterialFlagReceiveShadowsOff;
    #endif

    // Specular
    half3 packedSpecular;
    #ifdef _SPECULAR_SETUP
        materialFlags |= kMaterialFlagSpecularSetup;
        packedSpecular = specular.rgb;
    #else
        packedSpecular.r = reflectivity;
        packedSpecular.gb = 0.0;
    #endif
    #ifdef _SPECULARHIGHLIGHTS_OFF
        materialFlags |= kMaterialFlagSpecularHighlightsOff;
        packedSpecular = 0.0.xxx;
    #endif

    // Output
    FragmentOutput output;
    output.GBuffer0 = half4(albedo, PackMaterialFlags(materialFlags));  // diffuse           diffuse         diffuse         materialFlags   (sRGB rendertarget)
    output.GBuffer1 = half4(packedSpecular, occlusion);                 // metallic/specular specular        specular        occlusion
    output.GBuffer2 = half4(packedNormalWS, smoothness);                // encoded-normal    encoded-normal  encoded-normal  smoothness
    output.GBuffer3 = half4(globalIllumination, 1);                     // GI                GI              GI              unused          (lighting buffer)
    #if _RENDER_PASS_ENABLED
        output.GBuffer4 = positionCS.z;
    #endif
   
    return output;
}


FragmentOutput LitGBufferPassFragment(Varyings input)
{
    UNITY_SETUP_INSTANCE_ID(input);

    float2 uv = input.uv;
    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half3 albedo = texColor.rgb * _BaseColor.rgb;
    half3 specular = 0;
    half smoothness = 0;
    half reflectivity = 0;
    half occlusion = 0;
    float3 normalWS = NormalizeNormalPerPixel(input.normalWS);
    half3 globalIllumination = SampleSH(normalWS); //input.vertexSH;

    return InitializeGbufferData(input.positionCS, normalWS, albedo, specular, smoothness, reflectivity, occlusion, globalIllumination);
}


#endif