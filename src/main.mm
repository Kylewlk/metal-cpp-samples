
#include <iostream>
#include <filesystem>

#include "engine.hpp"

int main(int argc, const char * argv[])
{
    std::filesystem::current_path(CURRENT_WORKING_DIR);//setting path
    std::cout << "working path: " << std::filesystem::current_path() << std::endl;

    if(!std::filesystem::exists(".data/"))
    {
        std::filesystem::create_directories(".data");
    }

    MTLEngine engine;
    engine.init();
    engine.run();
    engine.cleanup();

    std::cout << "Exit!" << std::endl;
    return 0;
}
