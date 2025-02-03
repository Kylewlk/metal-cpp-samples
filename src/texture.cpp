
#include "texture.hpp"


Texture::Texture(const char* filepath, MTL::Device* device)
: device(device)
{
    auto imageData = stbi_load(filepath, &width, &height, &channels, STBI_rgb_alpha);
    assert(imageData);
    
    MTL::TextureDescriptor* textureDescriptor = MTL::TextureDescriptor::alloc()->init();
    textureDescriptor->setPixelFormat(MTL::PixelFormatRGBA8Unorm);
    textureDescriptor->setWidth(width);
    textureDescriptor->setHeight(height);
    
    texture = device->newTexture(textureDescriptor);
    
    MTL::Region region(0, 0, 0, width, height, 1);
    int bytesPerRow = 4 * width;
    
    texture->replaceRegion(region, 0, imageData, bytesPerRow);
    
    textureDescriptor->release();
    stbi_image_free(imageData);
}

Texture::~Texture()
{
    texture->release();
}
