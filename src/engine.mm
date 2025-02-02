
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
   
    triangleVertexBuffer->release();
    metalLibrary->release();
    metalCommandQueue->release();
    metalRenderPS0->release();
    metalDevice->release();
}

void MTLEngine::initDevice()
{
    metalDevice = MTL::CreateSystemDefaultDevice();
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
    simd::float3 triangleVertices[] = {
        {-0.5f, -0.5f, 0.0f},
        {0.5f, -0.5f, 0.0f},
        {0.0f, 0.5f, 0.0f},
    };
    
    triangleVertexBuffer = this->metalDevice->newBuffer(triangleVertices, sizeof(triangleVertices), MTL::ResourceStorageModeShared);
}

void MTLEngine::createLibrary()
{
    constexpr const char* shaderCode = R"(
#include <metal_stdlib>
using namespace metal;

#include <metal_stdlib>
using namespace metal;

vertex float4 vertexShader(uint vertexID [[vertex_id]],
             device const float3* positions [[buffer(0)]])
{
    return float4(positions[vertexID], 1.0);
}

fragment float4 fragmentShader(float4 vertexOutPositions [[stage_in]]) {
    return float4(182.0f/255.0f, 240.0f/255.0f, 228.0f/255.0f, 1.0f);
}

)";
    
    NS::Error* error = nullptr;
    this->metalLibrary = metalDevice->newLibrary(NS::String::string(shaderCode, NS::UTF8StringEncoding), nullptr, &error);
    if (!this->metalLibrary) {
        NSLog(@"Failed to create metal library:\n %s", error->localizedDescription()->utf8String());
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
    renderEncoder->setVertexBuffer(triangleVertexBuffer, 0, 0);
    renderEncoder->drawPrimitives(MTL::PrimitiveTypeTriangle, 0, 3, 1);
    
}
