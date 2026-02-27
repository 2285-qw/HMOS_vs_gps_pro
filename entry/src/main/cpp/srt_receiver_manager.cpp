/*
//
// Created by Vison on 2025/9/15.
//

#include "srt_receiver_manager.h"


SrtReceiverManager &SrtReceiverManager::GetInstance() {
    static SrtReceiverManager instance;
    return instance;
}

bool SrtReceiverManager::Init(JNIEnv *env, jint port, jobject callback) {
    std::lock_guard<std::mutex> lock(m_mutex);

    // 释放原有资源
    if (m_srtCallback != nullptr) {
        env->DeleteGlobalRef(m_srtCallback);
        m_srtCallback = nullptr;
    }
    m_srtReceiver.reset();

    // 从当前env获取JVM引用（仅初始化一次）
    if (!m_jvm) {
        if (env->GetJavaVM(&m_jvm) != 0) {
            LOGE("SrtReceiverManager: 获取JVM失败");
            return JNI_FALSE; // 获取JVM失败
        }
    }

    // 保存Java回调引用（全局引用）
    if (callback != nullptr) {
        m_srtCallback = env->NewGlobalRef(callback);
        if (m_srtCallback == nullptr) {
            LOGE("SrtReceiverManager: 创建回调全局引用失败");
            return false;
        }
    }
    // 初始化SRT配置
    m_config.port = port;

    //  创建SRT接收器实例
    try {
        m_srtReceiver = std::make_unique<srt_receiver::SrtReceiver>(m_config);
        m_srtReceiver->RegisterStreamCallback(OnSrtDataReceived);
        LOGI("SrtReceiverManager: 初始化成功，端口=%d", port);
        return true;
    } catch (...) {
        LOGE("SrtReceiverManager: 初始化失败");
        m_srtReceiver.reset();
        return false;
    }
}

bool SrtReceiverManager::Start() {
    std::lock_guard<std::mutex> lock(m_mutex);

    if (!m_srtReceiver) {
        LOGE("SrtReceiverManager: 未初始化，无法启动");
        return false;
    }

    if (m_srtReceiver->Start() == 0) {
        LOGI("SrtReceiverManager: 启动成功");
        return true;
    } else {
        LOGE("SrtReceiverManager: 启动失败");
        return false;
    }
}

void SrtReceiverManager::Stop() {
    std::lock_guard<std::mutex> lock(m_mutex);

    if (m_srtReceiver) {
        m_srtReceiver->Stop();
        LOGI("SrtReceiverManager: 已停止");
    }
}

void SrtReceiverManager::Release(JNIEnv *env) {
    std::lock_guard<std::mutex> lock(m_mutex);
    // 释放Java回调引用
    if (m_srtCallback != nullptr) {
        env->DeleteGlobalRef(m_srtCallback);
        m_srtCallback = nullptr;
        LOGI("SrtReceiverManager: 已释放回调引用");
    }

    //  释放SRT实例
    m_srtReceiver.reset();

    // 注意：不释放m_jvm（由虚拟机管理生命周期）
    LOGI("SrtReceiverManager: 所有资源已释放");
}

srt_receiver::SrtReceiver::Stats SrtReceiverManager::GetStats() {
    std::lock_guard<std::mutex> lock(m_mutex);

    if (m_srtReceiver) {
        return m_srtReceiver->GetStats();
    } else {
        LOGE("SrtReceiverManager: 未初始化，无法获取统计信息");
        return srt_receiver::SrtReceiver::Stats{};
    }
}


// SRT数据回调处理函数
void SrtReceiverManager::OnSrtDataReceived(void* data, size_t size) {
    // 1. 基础校验
    if (!data || size == 0) {
        LOGE("OnSrtDataReceived: 无效数据");
        return;
    }

    // 2. 获取管理器实例和必要引用
    auto& manager = GetInstance();
    JavaVM* jvm = manager.GetJvm();
    jobject callback = manager.GetCallback();

    if (!jvm || !callback) {
        LOGE("OnSrtDataReceived: JVM或回调未初始化");
        return;
    }

    // 3. 自动附着线程并获取JNIEnv
    JNIEnv* env = nullptr;
    JniThreadAttacher attacher(jvm, &env);
    if (!env) {
        LOGE("OnSrtDataReceived: 无法获取JNIEnv");
        return;
    }

    // 4. 调用Java层回调方法
    jclass callbackClass = env->GetObjectClass(callback);
    if (!callbackClass) {
        LOGE("OnSrtDataReceived: 无法获取回调类");
        return;
    }

    jmethodID onDataMethod = env->GetMethodID(callbackClass, "onDataReceived", "([B)V");
    if (!onDataMethod) {
        LOGE("OnSrtDataReceived: 未找到onDataReceived方法");
        env->DeleteLocalRef(callbackClass);
        return;
    }

    // 5. 传递数据到Java层
    jbyteArray dataArray = env->NewByteArray(size);
    env->SetByteArrayRegion(dataArray, 0, size, reinterpret_cast<const jbyte*>(data));
    env->CallVoidMethod(callback, onDataMethod, dataArray);

    // 6. 释放局部引用
    env->DeleteLocalRef(dataArray);
    env->DeleteLocalRef(callbackClass);

    //LOGD("OnSrtDataReceived: 已回调Java层，数据大小=%zu", size);
}
*/
