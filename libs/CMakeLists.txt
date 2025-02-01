cmake_minimum_required(VERSION 3.20)

set(target_name third_libs)
project(${target_name})

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 17)


add_library(${target_name} INTERFACE)

target_sources(${target_name} INTERFACE Lib.cpp)

set_target_properties(${target_name}
        PROPERTIES FOLDER "${libs}"
)

target_include_directories(${target_name} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)

# glfw
set(GLFW_BUILD_EXAMPLES OFF)
set(GLFW_BUILD_TESTS OFF)
set(GLFW_BUILD_DOCS OFF)
set(GLFW_INSTALL OFF)
add_subdirectory(glfw)
target_link_libraries(${target_name} INTERFACE glfw)

target_include_directories(${target_name} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/metal-cpp)
target_link_libraries( ${target_name} INTERFACE "-framework Foundation"  "-framework Metal" "-framework QuartzCore" "-framework MetalKit" "-framework AppKit")

set(metal_cpp_dir ${CMAKE_CURRENT_SOURCE_DIR}/metal-cpp)
file(GLOB_RECURSE metal_src_code LIST_DIRECTORIES FALSE ${metal_cpp_dir}/*.h ${metal_cpp_dir}/*.hpp)
add_library(MetalCpp STATIC ${metal_src_code} dummy.cpp)
source_group(TREE ${metal_cpp_dir} FILES ${metal_src_code})
