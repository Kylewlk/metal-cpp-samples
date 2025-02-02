
#pragma once

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3native.h>

#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.hpp>
#include <QuartzCore/QuartzCore.h>
#include <QuartzCore/CAMetalLayer.hpp>
#include <QuartzCore/CAMetalLayer.h>

class MTLEngine 
{
public:
    void init();
    void run();
    void cleanup();

private:

    void initDevice();
    void initWindow();
    
    void createTriangel();
    void createLibrary();
    void createCommandQueue();
    void createRenderPipline();
    
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    void sendRenderCommand();
    void draw();
    

    MTL::Device* metalDevice{};
    GLFWwindow* glfwWindow{};
    NSWindow* metalWindow{};
    CAMetalLayer* metalLayer{};
    CA::MetalDrawable* metalDrawable{};
    
    MTL::Library* metalLibrary{};
    MTL::CommandQueue* metalCommandQueue{};
    MTL::CommandBuffer* metalCommandBuffer{};
    MTL::RenderPipelineState* metalRenderPS0{};
    MTL::Buffer* triangleVertexBuffer{};
};



