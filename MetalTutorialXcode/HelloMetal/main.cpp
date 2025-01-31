//
//  main.cpp
//  HelloMetal
//
//  Created by Kyle on 2025/1/31.
//

#include <iostream>
#include <thread>

#include <Metal/Metal.hpp>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#include <GLFW/glfw3.h>

#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3native.h>


#pragma clang diagnostic pop


int main(int argc, const char * argv[])
{
    std::cout << "Start!!" << std::endl;
    
    glfwSetErrorCallback([](int error_code, const char* description){
        std::cerr << "GLFW Error, error code: " << error_code << ", Detail: " << description << std::endl;
    });
    
    glfwInit();
    
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    auto glfwWindow = glfwCreateWindow(800, 600, "Metal Engine", NULL, NULL);
    if (!glfwWindow) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    
//    MTL::Device* device = MTL::CreateSystemDefaultDevice();
//    device->release();
//    
    while (!glfwWindowShouldClose(glfwWindow)) {
        glfwPollEvents();
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    
    
    glfwDestroyWindow(glfwWindow);
    glfwTerminate();

    std::cout << "Exit!" << std::endl;
    return 0;
}
