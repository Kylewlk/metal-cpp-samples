
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

#include "texture.hpp"

class MTLEngine 
{
public:
    struct Vertex
    {
        float pos[3]{};
        float uv[2]{};
    };
    
    void init();
    void run();
    void cleanup();

private:

    void initDevice();
    void initWindow();
    
    void createRenderAttachments();
    void createSquare();
    void createLibrary();
    void createCommandQueue();
    void createRenderPipline();
    void createTexture();
    void createUboBuffer();
    
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    void sendRenderCommand();
    void draw();
    void updateUbo();
    

    MTL::Device* metalDevice{};
    GLFWwindow* glfwWindow{};
    NSWindow* metalWindow{};
    CAMetalLayer* metalLayer{};
    CA::MetalDrawable* metalDrawable{};
    
    int msaaSampleCount = 4;
    MTL::Texture* msaaTexture{};
    MTL::Texture* depthTexture{};
    MTL::DepthStencilState* depthState{};
    MTL::Library* metalLibrary{};
    MTL::CommandQueue* metalCommandQueue{};
    MTL::CommandBuffer* metalCommandBuffer{};
    MTL::RenderPipelineState* metalRenderPS0{};
    MTL::Buffer* vertexBuffer{};
    MTL::Buffer* uboBuffer{};
    
    Texture* image{};
    MTL::SamplerState* textureSampler{};
};



