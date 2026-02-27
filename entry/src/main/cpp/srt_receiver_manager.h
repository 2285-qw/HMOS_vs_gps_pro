/*
//
// Created by Vison on 2025/9/15.
//

#ifndef VISONNDK_SRT_RECEIVER_MANAGER_H
#define VISONNDK_SRT_RECEIVER_MANAGER_H

#include <mutex>
#include <memory>

#include "LogUtils.h"



// 适配现有代码的SRT接收器管理器（单例模式）
class SrtReceiverManager {
public:
    // 单例模式：全局唯一实例
    static SrtReceiverManager& GetInstance();

    // 禁止拷贝/赋值（避免多实例）
    SrtReceiverManager(const SrtReceiverManager&) = delete;
    SrtReceiverManager& operator=(const SrtReceiverManager&) = delete;

    // 初始化SRT接收器
   // bool Init(JNIEnv* env, jint port, jobject callback);

    // 启动SRT接收
    bool Start();

    // 停止SRT接收
    void Stop();

    // 释放所有SRT资源
   // void Release(JNIEnv* env);

    // 获取SRT统计信息
    srt_receiver::SrtReceiver::Stats GetStats();

    // 获取JVM引用（供回调使用）
    JavaVM* GetJvm() const {
        if (m_jvm == nullptr) {
            LOGE("JavaVM*未初始化，请先调用Init()");
            return nullptr;
        }
        return m_jvm;
    }

    // 获取Java回调引用（供回调使用）
    jobject GetCallback() const {
        return m_srtCallback;
    }

private:
    // 私有构造函数：仅单例可创建
    SrtReceiverManager() = default;

    // 私有析构函数：自动释放资源
    ~SrtReceiverManager() {
        m_srtReceiver.reset();
    }

    // SRT数据回调处理函数
    static void OnSrtDataReceived(void* data, size_t size);

private:
    std::unique_ptr<srt_receiver::SrtReceiver> m_srtReceiver; // SRT接收器实例
    std::mutex m_mutex;                                      // 线程安全锁
    JavaVM* m_jvm = nullptr;                                 // JVM全局引用
    jobject m_srtCallback = nullptr;                         // Java回调全局引用
    srt_receiver::SrtReceiver::SrtReceiverConfig m_config;   // SRT配置参数
};



#endif //VISONNDK_SRT_RECEIVER_MANAGER_H
*/
