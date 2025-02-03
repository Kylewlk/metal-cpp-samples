
#include "engine.hpp"

void MTLEngine::init()
{
    initDevice();
    initWindow();
    
    createSquare();
    createLibrary();
    createCommandQueue();
    createRenderPipline();
    createTexture();
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
   
    delete image;
    image = nullptr;
    vertexBuffer->release();
    indexBuffer->release();
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
    
    glfwInitHint(GLFW_COCOA_CHDIR_RESOURCES, GLFW_FALSE);
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
    
    glfwSetWindowUserPointer(glfwWindow, this);
    glfwSetWindowSizeCallback(glfwWindow, [](GLFWwindow* window, int width, int height){
        auto engine = (MTLEngine*)glfwGetWindowUserPointer(window);
        engine->metalLayer.drawableSize = CGSizeMake(width, height);
    });
}

void MTLEngine::createSquare()
{
    Vertex vertices[] = {
        {{-0.5f,  0.5f, 0.0f}, {0.0f, 0.0f}},
        {{-0.5f, -0.5f, 0.0f}, {0.0f, 1.0f}},
        {{ 0.5f, -0.5f, 0.0f}, {1.0f, 1.0f}},
        {{ 0.5f,  0.5f, 0.0f}, {1.0f, 0.0f}},
    };
    
    uint32_t indices[] = {
      0, 1, 2,
      3, 2, 0
    };

    vertexBuffer = this->metalDevice->newBuffer(vertices, sizeof(vertices), MTL::ResourceStorageModeShared);
    
    indexBuffer = this->metalDevice->newBuffer(indices, sizeof(indices), MTL::ResourceStorageModeShared);
}

void MTLEngine::createTexture()
{
    this->image = new Texture("assets/1.png", metalDevice);
}

void MTLEngine::createLibrary()
{
    constexpr const char* shaderCode = R"(
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
    
    MTL::VertexDescriptor* vertexDescriptor = MTL::VertexDescriptor::alloc()->init();
    MTL::VertexAttributeDescriptorArray* attributes = vertexDescriptor->attributes();
    
    MTL::VertexAttributeDescriptor* posDp = attributes->object(0);
    posDp->setFormat(MTL::VertexFormat::VertexFormatFloat3);
    posDp->setBufferIndex(0);
    posDp->setOffset(offsetof(Vertex, pos));
    
    MTL::VertexAttributeDescriptor* colorDp = attributes->object(1);
    colorDp->setFormat(MTL::VertexFormat::VertexFormatFloat2);
    colorDp->setBufferIndex(0);
    colorDp->setOffset(offsetof(Vertex, uv));
    
    MTL::VertexBufferLayoutDescriptor* vertexLayoutDp = vertexDescriptor->layouts()->object(0);
    vertexLayoutDp->setStride(sizeof(Vertex));
    vertexLayoutDp->setStepRate(1);
    vertexLayoutDp->setStepFunction(MTL::VertexStepFunction::VertexStepFunctionPerVertex);

    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setLabel(NS::String::string("Triangle Rendering Pipeline", NS::UTF8StringEncoding));
    renderPipelineDescriptor->setVertexDescriptor(vertexDescriptor);
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
    renderEncoder->setVertexBuffer(vertexBuffer, 0, 0);
    renderEncoder->setFragmentTexture(image->texture, 0);
    renderEncoder->drawIndexedPrimitives(MTL::PrimitiveTypeTriangle, 6, MTL::IndexTypeUInt32, indexBuffer, 0, 1);
//    renderEncoder->drawPrimitives(MTL::PrimitiveTypeTriangleStrip, 0, 4, 1);
    
}
