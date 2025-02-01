cmake_minimum_required(VERSION 3.20)


set(target_name MetalCppTutorial)
project(${target_name})

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 17)

add_subdirectory(libs)

file(GLOB_RECURSE src_code LIST_DIRECTORIES false
        src/*.hpp src/*.h src/*.cpp src/*.c src/*.m src/*.mm)

add_executable(${target_name} ${src_code})

target_link_libraries(${target_name} third_libs)

target_include_directories(${target_name} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_compile_definitions(${target_name} PRIVATE CURRENT_WORKING_DIR="${CMAKE_CURRENT_SOURCE_DIR}")

source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR}/src FILES ${src_code})