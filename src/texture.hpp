
#pragma once

#include <Metal/Metal.hpp>
#include <stb/stb_image.h>

class Texture
{
public:
    Texture(const char* filepath, MTL::Device* device);
    ~Texture();
    
    MTL::Texture* texture{};
    int width{};
    int height{};
    int channels;
    
private:
    MTL::Device* device{};
};




