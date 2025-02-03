
#include "engine.hpp"

#include <glm/glm.hpp>

#include <glm/ext/matrix_transform.hpp> // glm::translate, glm::rotate, glm::scale
#include <glm/ext/matrix_clip_space.hpp> // glm::perspective
#include <glm/ext/scalar_constants.hpp> // glm::pi


void MTLEngine::init()
{
    initDevice();
    initWindow();
    
    createRenderAttachments();
    createSquare();
    createLibrary();
    createCommandQueue();
    createRenderPipline();
    createTexture();
    createUboBuffer();
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
    textureSampler->release();
    vertexBuffer->release();
    uboBuffer->release();
    metalLibrary->release();
    metalCommandQueue->release();
    metalRenderPS0->release();
    msaaTexture->release();
    depthTexture->release();
    depthState->release();
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
        engine->createRenderAttachments();
    });
}

void MTLEngine::createRenderAttachments()
{
    int winWidth{};
    int winHeight{};
    glfwGetWindowSize(glfwWindow, &winWidth, &winHeight);
    
    if (winWidth <= 0 || winHeight <= 0) {
        return;
    }
    
    if (this->msaaTexture)
    {
        msaaTexture->release();
        msaaTexture = nullptr;
    }
    
    if (this->depthTexture) {
        depthTexture->release();
        depthTexture = nullptr;
    }
    
    
    MTL::TextureDescriptor* msaaDescriptor = MTL::TextureDescriptor::alloc()->init();
    msaaDescriptor->setTextureType(MTL::TextureType2DMultisample);
    msaaDescriptor->setPixelFormat((MTL::PixelFormat)metalLayer.pixelFormat);
    msaaDescriptor->setWidth(winWidth);
    msaaDescriptor->setHeight(winHeight);
    msaaDescriptor->setSampleCount(this->msaaSampleCount);
    msaaDescriptor->setUsage(MTL::TextureUsageRenderTarget);
    
    msaaTexture = metalDevice->newTexture(msaaDescriptor);
    
    
    MTL::TextureDescriptor* depthDescriptor = MTL::TextureDescriptor::alloc()->init();
    depthDescriptor->setTextureType(MTL::TextureType2DMultisample);
    depthDescriptor->setPixelFormat(MTL::PixelFormatDepth32Float);
    depthDescriptor->setWidth(winWidth);
    depthDescriptor->setHeight(winHeight);
    depthDescriptor->setSampleCount(this->msaaSampleCount);
    depthDescriptor->setUsage(MTL::TextureUsageRenderTarget);
    
    depthTexture = metalDevice->newTexture(depthDescriptor);
}

void MTLEngine::createSquare()
{
    Vertex vertices[] = {
        // Front face
        {{-0.5, -0.5, 0.5}, {0.0, 0.0}},
        {{0.5, -0.5, 0.5}, {1.0, 0.0}},
        {{0.5, 0.5, 0.5}, {1.0, 1.0}},
        {{0.5, 0.5, 0.5}, {1.0, 1.0}},
        {{-0.5, 0.5, 0.5}, {0.0, 1.0}},
        {{-0.5, -0.5, 0.5}, {0.0, 0.0}},
        
        // Back face
        {{0.5, -0.5, -0.5}, {0.0, 0.0}},
        {{-0.5, -0.5, -0.5}, {1.0, 0.0}},
        {{-0.5, 0.5, -0.5}, {1.0, 1.0}},
        {{-0.5, 0.5, -0.5}, {1.0, 1.0}},
        {{0.5, 0.5, -0.5}, {0.0, 1.0}},
        {{0.5, -0.5, -0.5}, {0.0, 0.0}},

        // Top face
        {{-0.5, 0.5, 0.5}, {0.0, 0.0}},
        {{0.5, 0.5, 0.5}, {1.0, 0.0}},
        {{0.5, 0.5, -0.5}, {1.0, 1.0}},
        {{0.5, 0.5, -0.5}, {1.0, 1.0}},
        {{-0.5, 0.5, -0.5}, {0.0, 1.0}},
        {{-0.5, 0.5, 0.5}, {0.0, 0.0}},

        // Bottom face
        {{-0.5, -0.5, -0.5}, {0.0, 0.0}},
        {{0.5, -0.5, -0.5}, {1.0, 0.0}},
        {{0.5, -0.5, 0.5}, {1.0, 1.0}},
        {{0.5, -0.5, 0.5}, {1.0, 1.0}},
        {{-0.5, -0.5, 0.5}, {0.0, 1.0}},
        {{-0.5, -0.5, -0.5}, {0.0, 0.0}},

        // Left face
        {{-0.5, -0.5, -0.5}, {0.0, 0.0}},
        {{-0.5, -0.5, 0.5}, {1.0, 0.0}},
        {{-0.5, 0.5, 0.5}, {1.0, 1.0}},
        {{-0.5, 0.5, 0.5}, {1.0, 1.0}},
        {{-0.5, 0.5, -0.5}, {0.0, 1.0}},
        {{-0.5, -0.5, -0.5}, {0.0, 0.0}},

        // Right face
        {{0.5, -0.5, 0.5}, {0.0, 0.0}},
        {{0.5, -0.5, -0.5}, {1.0, 0.0}},
        {{0.5, 0.5, -0.5}, {1.0, 1.0}},
        {{0.5, 0.5, -0.5}, {1.0, 1.0}},
        {{0.5, 0.5, 0.5}, {0.0, 1.0}},
        {{0.5, -0.5, 0.5}, {0.0, 0.0}},
    };

    vertexBuffer = this->metalDevice->newBuffer(vertices, sizeof(vertices), MTL::ResourceStorageModeShared);

}

void MTLEngine::createTexture()
{
    this->image = new Texture("assets/mc_grass.jpeg", metalDevice);
    
    auto samplerDescriptor = MTL::SamplerDescriptor::alloc()->init();
    samplerDescriptor->setLabel(NS::String::string("SamplerLinner", NS::UTF8StringEncoding));
    samplerDescriptor->setMagFilter(MTL::SamplerMinMagFilterLinear);
    samplerDescriptor->setMinFilter(MTL::SamplerMinMagFilterLinear);
    
    this->textureSampler = this->metalDevice->newSamplerState(samplerDescriptor);
}

void MTLEngine::createUboBuffer()
{
    this->uboBuffer = this->metalDevice->newBuffer(sizeof(glm::mat4), MTL::ResourceStorageModeShared);
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
    auto colorAttachment = renderPipelineDescriptor->colorAttachments()->object(0);
    colorAttachment->setPixelFormat(pixelFormat);
    colorAttachment->setBlendingEnabled(true);
    colorAttachment->setRgbBlendOperation(MTL::BlendOperationAdd);
    colorAttachment->setSourceRGBBlendFactor(MTL::BlendFactorSourceAlpha);
    colorAttachment->setDestinationRGBBlendFactor(MTL::BlendFactorOneMinusSourceAlpha);
    
    renderPipelineDescriptor->setDepthAttachmentPixelFormat(depthTexture->pixelFormat());

    renderPipelineDescriptor->setSampleCount(this->msaaSampleCount);
    
    MTL::DepthStencilDescriptor* depthStencilDescriptor = MTL::DepthStencilDescriptor::alloc()->init();
    depthStencilDescriptor->setLabel(NS::String::string("DepthState", NS::UTF8StringEncoding));
    depthStencilDescriptor->setDepthWriteEnabled(true);
    depthStencilDescriptor->setDepthCompareFunction(MTL::CompareFunctionLessEqual);
    this->depthState = metalDevice->newDepthStencilState(depthStencilDescriptor);
    
    NS::Error* error = nullptr;
    metalRenderPS0 = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    assert(metalRenderPS0);
    
//    depthStencilDescriptor->release();
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
    
    auto ca = renderPassDescriptor->colorAttachments()->object(0);
    ca->setTexture(msaaTexture);
    ca->setResolveTexture(metalDrawable->texture());
    ca->setClearColor(MTL::ClearColor(0.2f, 0.2f, 0.2f, 1.0f));
    ca->setLoadAction(MTL::LoadActionClear);
    ca->setStoreAction(MTL::StoreActionMultisampleResolve);
    
    auto da = renderPassDescriptor->depthAttachment();
    da->setTexture(depthTexture);
    da->setLoadAction(MTL::LoadActionClear);
    da->setStoreAction(MTL::StoreActionDontCare);
    da->setClearDepth(1.0);
    
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
    this->updateUbo();
    
    renderEncoder->setLabel(NS::String::string("DrawCube", NS::UTF8StringEncoding));

    renderEncoder->setRenderPipelineState(metalRenderPS0);
    renderEncoder->setDepthStencilState(depthState);
    renderEncoder->setVertexBuffer(vertexBuffer, 0, 0);
    renderEncoder->setVertexBuffer(uboBuffer, 0, 1);
    renderEncoder->setFragmentTexture(image->texture, 0);
    renderEncoder->setFragmentSamplerState(textureSampler, 0);
    renderEncoder->drawPrimitives(MTL::PrimitiveTypeTriangle, 0, 36, 1);
    
}

void MTLEngine::updateUbo()
{
    auto rotation = (float)std::fmod(glfwGetTime(), 2.0 * 3.1415926);
    
    glm::mat4 model = glm::mat4(1.0f);
    model = glm::rotate(model, rotation, {0.5f, 1.0f, 0.0f});
    
    glm::mat4 view = glm::lookAt<float, glm::defaultp>({0.0f, 0.0f, 3.0f}, {0.0f, 0.0f, 0.0f}, {0.0f, 1.0f, 0.0f});
    
    int winWidth{};
    int winHeight{};
    glfwGetWindowSize(glfwWindow, &winWidth, &winHeight);
    float aspect = static_cast<float>(winWidth) / static_cast<float>(winHeight);
    glm::mat4 proj = glm::perspectiveRH_ZO(glm::radians(60.0f), aspect, 0.1f, 10.0f);
    
    glm::mat4 mvp = proj * view * model;
    
    memcpy(uboBuffer->contents(), &mvp, sizeof(mvp));
}
