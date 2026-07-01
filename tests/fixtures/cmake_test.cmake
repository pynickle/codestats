
cmake_minimum_required(VERSION 3.10)
# Pure comment
project(TestProject)  # Mixed: code + comment

set(CMAKE_CXX_STANDARD 17)
add_executable(app main.cpp)

target_link_libraries(app pthread)  # Another mixed line

install(TARGETS app)
