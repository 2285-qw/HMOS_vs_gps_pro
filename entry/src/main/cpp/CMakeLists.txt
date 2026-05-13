# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(MyApplication)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})


if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

# 递归收集所有 .cpp 文件
file(GLOB_RECURSE SRC_LIST "${PROJECT_SOURCE_DIR}/\*.cpp")


add_library(entry SHARED  ${SRC_LIST})

target_link_libraries(entry PUBLIC libace_napi.z.so)
target_link_libraries(entry PUBLIC libhilog_ndk.z.so)
target_link_libraries(entry PUBLIC libnative_media_codecbase.so)
target_link_libraries(entry PUBLIC libnative_media_core.so)
target_link_libraries(entry PUBLIC libnative_media_vdec.so)
target_link_libraries(entry PUBLIC libnative_window.so)
target_link_libraries(entry PUBLIC libnative_media_avmuxer.so)




