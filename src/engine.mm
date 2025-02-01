
#include "engine.hpp"

void MTLEngine::init()
{
    initDevice();
    initWindow();
}

void MTLEngine::run()
{
    while (!glfwWindowShouldClose(glfwWindow))
    {
        glfwPollEvents();
    }
}

void MTLEngine::cleanup()
{
    glfwDestroyWindow(glfwWindow);
    glfwWindow = nullptr;
    glfwTerminate();
    
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
