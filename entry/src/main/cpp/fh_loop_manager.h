//
// Created by Vison on 2025/9/18.
//

#ifndef VISONNDK_FH_LOOP_MANAGER_H
#define VISONNDK_FH_LOOP_MANAGER_H

#include "napi.h"
#include <memory>
#include "LoopBuf.h"
#include "LogUtils.h"
#include "BLoopBufData.h"
#include "_872Stream.h"
#include "NetProtocol.h"


class FHLoopManager {
public:
    static FHLoopManager &GetInstance();

    FHLoopManager(const FHLoopManager &) = delete;

    FHLoopManager &operator=(const FHLoopManager &) = delete;

    /* 视频流循环buffer处理*/
    // 创建视频缓冲区，返回是否成功
    static napi_value createVideoStream(napi_env env, napi_callback_info type);

    // 添加视频数据（需传入JNIEnv）
    static napi_value addVideoStream(napi_env env, napi_callback_info data);

    // 添加872格式视频数据（需传入JNIEnv）
    void addVideoStream872(napi_env env, napi_value data, jint dataLength);

    // 获取一帧视频数据（返回字节数组） 两个值 第一个是一帧的数据 第二个值是是否连续针
    static napi_value getVideoOneFrameArray(napi_env env, napi_callback_info header);

    // 获取一帧视频数据（写入用户提供的buffer）
    jint getVideoOneFrameBuffer(napi_env env, jboolean check_continuity, napi_value buffer, napi_value header);

    // 释放视频缓冲区资源
    void releaseVideoStream();

    /* 音频流循环buffer处理*/
    // 创建音频缓冲区，返回是否成功
    bool createAudioStream();

    // 添加音频数据
    void addAudioStream(napi_env env, napi_value data, int dataLength);

    // 获取一帧音频数据
    napi_value getAudioOneFrame(napi_env env);

    // 释放音频缓冲区资源
    void releaseAudioStream();
    
    
    
    //解码相关
    
    

private:
    FHLoopManager() : myVideoLoopBufHandle(nullptr), myAudioLoopBufHandle(nullptr){};

    ~FHLoopManager() {
        releaseVideoStream();
        releaseAudioStream();
    };

    // 视频环形buff
    BLHANDLE myVideoLoopBufHandle;

    // 音频环形buff
    BLHANDLE myAudioLoopBufHandle;

    // 872格式流缓冲区
    std::unique_ptr<char[]> p872StreamBuf;

    // 视频帧数据缓冲区
    std::unique_ptr<char[]> pVideoFrame;

    // 音频帧数据缓冲区
    std::unique_ptr<char[]> pAudioFrame;

    // 当前帧的index
    int nowFrameIndex = 0;

    // 是否需要I帧
    bool isNeedIFrame = true;
};


#endif // VISONNDK_FH_LOOP_MANAGER_H
