
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

    MTL::Device* metalDevice{};
    GLFWwindow* glfwWindow{};
    NSWindow* metalWindow{};
    CAMetalLayer* metalLayer;
};



