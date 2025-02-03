
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


vertex VertexOut vertexShader(VertexInput vi [[stage_in]])
{
    VertexOut vo;
    vo.position = float4(vi.position, 1.0);
    vo.texCoord = vi.texCoord;
    return vo;
}

fragment half4 fragmentShader(VertexOut vo[[stage_in]],
                              texture2d<float> image [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    const float4 color = image.sample(textureSampler, vo.texCoord);
    return half4(color);
}



