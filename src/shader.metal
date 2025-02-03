
#include <metal_stdlib>
using namespace metal;

struct VertexOut
{
    float4 position [[position]];
    float2 texCoord;
};

struct VertexInput
{
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};


vertex VertexOut vertexShader(VertexInput vi [[stage_in]],
                              constant float4x4& mvp [[buffer(1)]])
{
    VertexOut vo;
    vo.position = mvp * float4(vi.position, 1.0);
    vo.texCoord = vi.texCoord;
    return vo;
}

fragment half4 fragmentShader(VertexOut vo[[stage_in]],
                              texture2d<half> image [[texture(0)]],
                              sampler textureSampler [[sampler(0)]]) {
//    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    auto color = image.sample(textureSampler, vo.texCoord);
    return half4(color);
}



