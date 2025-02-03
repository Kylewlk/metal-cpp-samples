
#include "engine.hpp"
#include <simd/simd.h>

void MTLEngine::init()
{
    initDevice();
    initWindow();
    
    createTriangel();
    createLibrary();
    createCommandQueue();
    createRenderPipline();
}

void MTLEngine::run()
{
    while (!glfwWindowShouldClose(glfwWindow))
    {
        @autoreleasepool {
            metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
            draw();
        }
        glfwPollEvents();
    }
}

void MTLEngine::cleanup()
{
    glfwDestroyWindow(glfwWindow);
    glfwWindow = nullptr;
    glfwTerminate();
   
    vertexBuffer->release();
    colorBuffer->release();
    argBuffer->release();
    metalLibrary->release();
    metalCommandQueue->release();
    metalRenderPS0->release();
    metalDevice->release();
}

void MTLEngine::initDevice()
{
    metalDevice = MTL::CreateSystemDefaultDevice();
    
    NSLog(@"Metal Device: %@", (__bridge NSString*)metalDevice->name());
    
}

void MTLEngine::initWindow()
{
    glfwSetErrorCallback([](int error_code, const char* description){
        NSLog(@"GLFW Error, error code: %d, Detail: %s ", error_code, description);
    });
    
    glfwInit();
    
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(800, 600, "Metal Engine", NULL, NULL);
    if (!glfwWindow) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    
    metalWindow = glfwGetCocoaWindow(glfwWindow);
    metalLayer = [CAMetalLayer layer];
    metalLayer.device = (__bridge id<MTLDevice>)metalDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalWindow.contentView.layer = metalLayer;
    metalWindow.contentView.wantsLayer = YES;
    
}

void MTLEngine::createTriangel()
{
//    Vertex triangleVertices[] = {
//        {{-0.5f, -0.5f, 0.0f}, {1.0f, 0.0f, 0.0f, 1.0f}},
//        {{0.5f, -0.5f, 0.0f}, {0.0f, 1.0f, 0.0f, 1.0f}},
//        {{0.0f, 0.5f, 0.0f}, {0.0f, 0.0f, 1.0f, 1.0f}},
//    };
    
    simd::float3 vertices[] = {
        {-0.5f, -0.5f, 0.0f},
        {0.5f, -0.5f, 0.0f},
        {0.0f, 0.5f, 0.0f},
    };
    simd::float3 colors[] = {
        {1.0f, 0.0f, 0.0f},
        {0.0f, 1.0f, 0.0f},
        {0.0f, 0.0f, 1.0f},
    };

    vertexBuffer = this->metalDevice->newBuffer(vertices, sizeof(vertices), MTL::ResourceStorageModeShared);
    colorBuffer = this->metalDevice->newBuffer(colors, sizeof(colors), MTL::ResourceStorageModeShared);
}

void MTLEngine::createLibrary()
{
    constexpr const char* shaderCode = R"(
#include <metal_stdlib>
using namespace metal;

struct VertexOut
{
    float4 position [[position]];
    half3 color;
};

struct VertexInput
{
    device float3* positions [[id(0)]];
    device float3* colors [[id(1)]];
};


vertex VertexOut vertexShader(uint vertexID [[vertex_id]], device const VertexInput* vi [[buffer(0)]])
{
    VertexOut vo;
    vo.position = float4(vi->positions[vertexID], 1.0);
    vo.color = half3(vi->colors[vertexID]);
    return vo;
}

fragment half4 fragmentShader(VertexOut vertexOut[[stage_in]]) {
    return half4(vertexOut.color, 1.0);
}
)";
    
    NS::Error* error = nullptr;
    this->metalLibrary = metalDevice->newLibrary(NS::String::string(shaderCode, NS::UTF8StringEncoding), nullptr, &error);
    if (!this->metalLibrary) {
        NSLog(@"Failed to create metal library:\n %@",  (__bridge NSString*)error->localizedDescription());
        exit(EXIT_FAILURE);
    }
}

void MTLEngine::createCommandQueue()
{
    metalCommandQueue = this->metalDevice->newCommandQueue();
}

void MTLEngine::createRenderPipline()
{
    MTL::Function* vertexShader = metalLibrary->newFunction(NS::String::string("vertexShader", NS::UTF8StringEncoding));
    assert(vertexShader);
    MTL::Function* fragmentShader = metalLibrary->newFunction(NS::String::string("fragmentShader", NS::UTF8StringEncoding));
    assert(fragmentShader);
    
    MTL::ArgumentEncoder* argEncoder = vertexShader->newArgumentEncoder(0);
    argBuffer = this->metalDevice->newBuffer(argEncoder->encodedLength(), MTL::ResourceStorageModeManaged);
    argEncoder->setArgumentBuffer(argBuffer, 0);
    argEncoder->setBuffer(vertexBuffer, 0, 0);
    argEncoder->setBuffer(colorBuffer, 0, 1);
    argEncoder->release();
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setLabel(NS::String::string("Triangle Rendering Pipeline", NS::UTF8StringEncoding));
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
    
    NS::Error* error = nullptr;
    metalRenderPS0 = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    assert(metalRenderPS0);
    
    renderPipelineDescriptor->release();
    vertexShader->release();
    fragmentShader->release();
}

void MTLEngine::draw()
{
    sendRenderCommand();
}

void MTLEngine::sendRenderCommand()
{
    metalCommandBuffer = metalCommandQueue->commandBuffer();
    
    MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    auto cd = renderPassDescriptor->colorAttachments()->object(0);
    cd->setTexture(metalDrawable->texture());
    cd->setClearColor(MTL::ClearColor(0.2f, 0.2f, 0.2f, 1.0f));
    cd->setLoadAction(MTL::LoadActionClear);
    cd->setStoreAction(MTL::StoreActionStore);
    
    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();
    
    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();
    
    renderPassDescriptor->release();
}

void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder *renderEncoder)
{
    renderEncoder->setRenderPipelineState(metalRenderPS0);
    renderEncoder->setVertexBuffer(argBuffer, 0, 0);
    renderEncoder->useResource(vertexBuffer, MTL::ResourceUsageRead);
    renderEncoder->useResource(colorBuffer, MTL::ResourceUsageRead);
    renderEncoder->drawPrimitives(MTL::PrimitiveTypeTriangle, 0, 3, 1);
    
}
