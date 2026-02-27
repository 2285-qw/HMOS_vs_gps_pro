// VideoDecoderNAPI.cpp
#include "napi/native_api.h"
#include "hilog/log.h"
#include <cstring>
#include <string>
#include <memory>
#include <queue>
#include <mutex>

#include "hmos_video_decoder.h"

// 日志标签
#define LOG_TAG "VideoDecoderNapi"
#define LOGD(fmt, ...) OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGI(fmt, ...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGE(fmt, ...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)

// 回调数据结构
struct FrameCallbackData {
    VideoFramePtr frame;
};

struct ErrorCallbackData {
    int32_t errorCode;
};

struct FormatChangedCallbackData {
    int32_t width;
    int32_t height;
    int32_t format;
};

// 全局解码器上下文
static struct {
    HmosVideoDecoder* decoder = nullptr;
    bool isInitialized = false;
    // 回调引用
    napi_ref frameCallbackRef = nullptr;
    napi_ref errorCallbackRef = nullptr;
    napi_ref formatChangedCallbackRef = nullptr;
    
    // 线程安全函数
    napi_threadsafe_function frameThreadsafeFunction = nullptr;
    napi_threadsafe_function errorThreadsafeFunction = nullptr;
    napi_threadsafe_function formatChangedThreadsafeFunction = nullptr;
    
    // 线程安全队列（使用智能指针）
    std::queue<VideoFramePtr> frameQueue;
    std::mutex queueMutex;
    
    // 当前环境
    napi_env currentEnv = nullptr;
} g_decoderContext;

// 创建视频帧对象
static napi_value CreateVideoFrameObject(napi_env env, const VideoFramePtr& frame) {
    napi_value result;
    napi_create_object(env, &result);
    
    if (!frame) {
        return result;
    }
    
    // 创建 ArrayBuffer 存储帧数据
    napi_value arrayBuffer;
    size_t totalSize = frame->data.size();
    
    void* data = nullptr;
    napi_create_arraybuffer(env, totalSize, &data, &arrayBuffer);
    if (data && !frame->data.empty()) {
        memcpy(data, frame->data.data(), totalSize);
    }
    
    // 设置属性
    napi_value widthValue;
    napi_create_int32(env, frame->width, &widthValue);
    napi_set_named_property(env, result, "width", widthValue);
    
    napi_value heightValue;
    napi_create_int32(env, frame->height, &heightValue);
    napi_set_named_property(env, result, "height", heightValue);
    
    napi_value strideValue;
    napi_create_int32(env, frame->stride, &strideValue);
    napi_set_named_property(env, result, "stride", strideValue);
    
    napi_value timestampValue;
    napi_create_int64(env, frame->timestamp, &timestampValue);
    napi_set_named_property(env, result, "timestamp", timestampValue);
    
    napi_value formatValue;
    napi_create_int32(env, frame->format, &formatValue);
    napi_set_named_property(env, result, "format", formatValue);
    
    napi_set_named_property(env, result, "data", arrayBuffer);
    
    return result;
}

// 帧回调执行器 - 在 JavaScript 主线程执行
static void FrameThreadsafeFunctionExecutor(napi_env env, void* data, napi_value* result) {
    if (!env || !data) {
        return;
    }
    
    FrameCallbackData* callbackData = static_cast<FrameCallbackData*>(data);
    if (!callbackData->frame) {
        delete callbackData;
        return;
    }
    
    // 获取回调函数
    napi_value callback;
    napi_get_reference_value(env, g_decoderContext.frameCallbackRef, &callback);
    
    // 创建帧对象
    napi_value frameObj = CreateVideoFrameObject(env, callbackData->frame);
    
    // 调用回调 - 此调用在主线程执行
    napi_value jsResult;
    napi_call_function(env, nullptr, callback, 1, &frameObj, &jsResult);
    
    // 释放数据
    delete callbackData;
}

// 错误回调执行器 - 在 JavaScript 主线程执行
static void ErrorThreadsafeFunctionExecutor(napi_env env, void* data, napi_value* result) {
    if (!env || !data) {
        return;
    }
    
    ErrorCallbackData* callbackData = static_cast<ErrorCallbackData*>(data);
    
    // 获取回调函数
    napi_value callback;
    napi_get_reference_value(env, g_decoderContext.errorCallbackRef, &callback);
    
    // 创建错误码参数
    napi_value errorValue;
    napi_create_int32(env, callbackData->errorCode, &errorValue);
    
    // 调用回调 - 此调用在主线程执行
    napi_value jsResult;
    napi_call_function(env, nullptr, callback, 1, &errorValue, &jsResult);
    
    // 释放数据
    delete callbackData;
}

// 格式变更回调执行器 - 在 JavaScript 主线程执行
static void FormatChangedThreadsafeFunctionExecutor(napi_env env, void* data, napi_value* result) {
    if (!env || !data) {
        return;
    }
    
    FormatChangedCallbackData* callbackData = static_cast<FormatChangedCallbackData*>(data);
    
    // 获取回调函数
    napi_value callback;
    napi_get_reference_value(env, g_decoderContext.formatChangedCallbackRef, &callback);
    
    // 创建参数对象
    napi_value formatObj;
    napi_create_object(env, &formatObj);
    
    napi_value widthValue;
    napi_create_int32(env, callbackData->width, &widthValue);
    napi_set_named_property(env, formatObj, "width", widthValue);
    
    napi_value heightValue;
    napi_create_int32(env, callbackData->height, &heightValue);
    napi_set_named_property(env, formatObj, "height", heightValue);
    
    napi_value formatValue;
    napi_create_int32(env, callbackData->format, &formatValue);
    napi_set_named_property(env, formatObj, "format", formatValue);
    
    // 调用回调 - 此调用在主线程执行
    napi_value jsResult;
    napi_call_function(env, nullptr, callback, 1, &formatObj, &jsResult);
    
    // 释放数据
    delete callbackData;
}

// 帧回调包装函数
static void OnFrameCallbackWrapper(VideoFramePtr frame) {
    if (!frame) {
        return;
    }
    
    // 如果有线程安全函数，使用线程安全函数调用
    if (g_decoderContext.frameThreadsafeFunction) {
        // 创建回调数据
        FrameCallbackData* callbackData = new FrameCallbackData();
        callbackData->frame = frame;
        
        // 调用线程安全函数，将回调任务提交到主线程
        napi_status status = napi_call_threadsafe_function(
            g_decoderContext.frameThreadsafeFunction,
            callbackData,
            napi_tsfn_nonblocking
        );
        
        if (status != napi_ok) {
            LOGE("Failed to call frame threadsafe function: %d", status);
            delete callbackData;
        }
    } else {
        // 如果没有回调，将帧加入队列供同步获取
        std::lock_guard<std::mutex> lock(g_decoderContext.queueMutex);
        g_decoderContext.frameQueue.push(frame);
    }
}

// 错误回调包装函数
static void OnErrorCallbackWrapper(int32_t errorCode) {
    // 如果有线程安全函数，使用线程安全函数调用
    if (g_decoderContext.errorThreadsafeFunction) {
        // 创建回调数据
        ErrorCallbackData* callbackData = new ErrorCallbackData();
        callbackData->errorCode = errorCode;
        
        // 调用线程安全函数，将回调任务提交到主线程
        napi_status status = napi_call_threadsafe_function(
            g_decoderContext.errorThreadsafeFunction,
            callbackData,
            napi_tsfn_nonblocking
        );
        
        if (status != napi_ok) {
            LOGE("Failed to call error threadsafe function: %d", status);
            delete callbackData;
        }
    }
}

// 格式变更回调包装函数
static void OnFormatChangedCallbackWrapper(int32_t width, int32_t height, int32_t format) {
    // 如果有线程安全函数，使用线程安全函数调用
    if (g_decoderContext.formatChangedThreadsafeFunction) {
        // 创建回调数据
        FormatChangedCallbackData* callbackData = new FormatChangedCallbackData();
        callbackData->width = width;
        callbackData->height = height;
        callbackData->format = format;
        
        // 调用线程安全函数，将回调任务提交到主线程
        napi_status status = napi_call_threadsafe_function(
            g_decoderContext.formatChangedThreadsafeFunction,
            callbackData,
            napi_tsfn_nonblocking
        );
        
        if (status != napi_ok) {
            LOGE("Failed to call format changed threadsafe function: %d", status);
            delete callbackData;
        }
    }
}

// 初始化全局解码器
static void InitGlobalDecoder() {
    if (!g_decoderContext.decoder) {
        g_decoderContext.decoder = new HmosVideoDecoder();
        LOGI("Global decoder created");
    }
}

// 释放全局解码器
static void FreeGlobalDecoder() {
    if (g_decoderContext.decoder) {
        g_decoderContext.decoder->release();
        delete g_decoderContext.decoder;
        g_decoderContext.decoder = nullptr;
    }
    
    // 清理帧队列（智能指针会自动释放）
    {
        std::lock_guard<std::mutex> lock(g_decoderContext.queueMutex);
        std::queue<VideoFramePtr> empty;
        std::swap(g_decoderContext.frameQueue, empty);
    }
    
    // 释放线程安全函数
    if (g_decoderContext.frameThreadsafeFunction) {
        napi_release_threadsafe_function(g_decoderContext.frameThreadsafeFunction, napi_tsfn_release);
        g_decoderContext.frameThreadsafeFunction = nullptr;
    }
    
    if (g_decoderContext.errorThreadsafeFunction) {
        napi_release_threadsafe_function(g_decoderContext.errorThreadsafeFunction, napi_tsfn_release);
        g_decoderContext.errorThreadsafeFunction = nullptr;
    }
    
    if (g_decoderContext.formatChangedThreadsafeFunction) {
        napi_release_threadsafe_function(g_decoderContext.formatChangedThreadsafeFunction, napi_tsfn_release);
        g_decoderContext.formatChangedThreadsafeFunction = nullptr;
    }
    
    // 删除回调引用
    if (g_decoderContext.frameCallbackRef && g_decoderContext.currentEnv) {
        napi_delete_reference(g_decoderContext.currentEnv, g_decoderContext.frameCallbackRef);
        g_decoderContext.frameCallbackRef = nullptr;
    }
    
    if (g_decoderContext.errorCallbackRef && g_decoderContext.currentEnv) {
        napi_delete_reference(g_decoderContext.currentEnv, g_decoderContext.errorCallbackRef);
        g_decoderContext.errorCallbackRef = nullptr;
    }
    
    if (g_decoderContext.formatChangedCallbackRef && g_decoderContext.currentEnv) {
        napi_delete_reference(g_decoderContext.currentEnv, g_decoderContext.formatChangedCallbackRef);
        g_decoderContext.formatChangedCallbackRef = nullptr;
    }
    
    g_decoderContext.isInitialized = false;
    g_decoderContext.currentEnv = nullptr;
    
    LOGI("Global decoder freed");
}

// ==================== NAPI 函数定义 ====================

// NAPI: 初始化解码器
static napi_value Initialize(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];
    
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // 保存当前环境
    g_decoderContext.currentEnv = env;
    
    // 初始化全局解码器
    InitGlobalDecoder();
    
    if (!g_decoderContext.decoder) {
        napi_throw_error(env, nullptr, "Failed to create decoder");
        return nullptr;
    }
    
    // 获取参数
    char mimeType[256];
    size_t mimeTypeLength;
    napi_get_value_string_utf8(env, args[0], mimeType, sizeof(mimeType), &mimeTypeLength);
    
    int32_t width, height;
    napi_get_value_int32(env, args[1], &width);
    napi_get_value_int32(env, args[2], &height);
    
    // 调用解码器初始化
    bool success = g_decoderContext.decoder->initialize(std::string(mimeType), width, height);
    g_decoderContext.isInitialized = success;
    
    // 返回结果
    napi_value result;
    napi_get_boolean(env, success, &result);
    return result;
}

// NAPI: 设置Surface（用于渲染模式）
static napi_value SetSurface(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    if (!g_decoderContext.decoder || !g_decoderContext.isInitialized) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }
    
    // 获取native window指针
    void* nativeWindow = nullptr;
    napi_get_value_external(env, args[0], &nativeWindow);
    
    // 设置Surface
    bool success = g_decoderContext.decoder->setSurface(static_cast<OHNativeWindow*>(nativeWindow));
    
    // 返回结果
    napi_value result;
    napi_get_boolean(env, success, &result);
    return result;
}

// NAPI: 设置回调函数
static napi_value SetCallbacks(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3];

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 保存当前环境
    g_decoderContext.currentEnv = env;

    if (!g_decoderContext.decoder || !g_decoderContext.isInitialized) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }

    // 更新回调引用
    if (argc > 0) {
        napi_valuetype valuetype;
        napi_typeof(env, args[0], &valuetype);

        if (valuetype == napi_function) {
            if (g_decoderContext.frameCallbackRef) {
                napi_delete_reference(env, g_decoderContext.frameCallbackRef);
            }
            napi_create_reference(env, args[0], 1, &g_decoderContext.frameCallbackRef);
        } else if (valuetype == napi_null || valuetype == napi_undefined) {
            if (g_decoderContext.frameCallbackRef) {
                napi_delete_reference(env, g_decoderContext.frameCallbackRef);
                g_decoderContext.frameCallbackRef = nullptr;
            }
        }
    }

    if (argc > 1) {
        napi_valuetype valuetype;
        napi_typeof(env, args[1], &valuetype);

        if (valuetype == napi_function) {
            if (g_decoderContext.errorCallbackRef) {
                napi_delete_reference(env, g_decoderContext.errorCallbackRef);
            }
            napi_create_reference(env, args[1], 1, &g_decoderContext.errorCallbackRef);
        } else if (valuetype == napi_null || valuetype == napi_undefined) {
            if (g_decoderContext.errorCallbackRef) {
                napi_delete_reference(env, g_decoderContext.errorCallbackRef);
                g_decoderContext.errorCallbackRef = nullptr;
            }
        }
    }

    if (argc > 2) {
        napi_valuetype valuetype;
        napi_typeof(env, args[2], &valuetype);

        if (valuetype == napi_function) {
            if (g_decoderContext.formatChangedCallbackRef) {
                napi_delete_reference(env, g_decoderContext.formatChangedCallbackRef);
            }
            napi_create_reference(env, args[2], 1, &g_decoderContext.formatChangedCallbackRef);
        } else if (valuetype == napi_null || valuetype == napi_undefined) {
            if (g_decoderContext.formatChangedCallbackRef) {
                napi_delete_reference(env, g_decoderContext.formatChangedCallbackRef);
                g_decoderContext.formatChangedCallbackRef = nullptr;
            }
        }
    }

    // 使用 lambda 包装器设置回调
    g_decoderContext.decoder->setCallbacks(
        [](VideoFramePtr frame) { OnFrameCallbackWrapper(frame); },
        [](int32_t errorCode) { OnErrorCallbackWrapper(errorCode); },
        [](int32_t width, int32_t height, int32_t format) { OnFormatChangedCallbackWrapper(width, height, format); });

    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// NAPI: 解码帧（使用TypedArray版本）
static napi_value DecodeFrameTypedArray(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 2) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    if (!g_decoderContext.decoder || !g_decoderContext.isInitialized) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }
    
    // 获取数据参数
    bool isTypedArray;
    napi_is_typedarray(env, args[0], &isTypedArray);
    
    void* bufferData = nullptr;
    size_t length = 0;
    uint32_t flags = AVCODEC_BUFFER_FLAGS_NONE;
    
    if (isTypedArray) {
        napi_typedarray_type type;
        napi_value buffer;
        
        napi_get_typedarray_info(env, args[0], &type, &length, &bufferData, &buffer, nullptr);
        
        if (type != napi_uint8_array) {
            napi_throw_error(env, nullptr, "Expected Uint8Array for frame data");
            return nullptr;
        }
        
        // 检查是否为EOS帧（空数组可能表示EOS）
        if (length == 0) {
            flags = AVCODEC_BUFFER_FLAGS_EOS;
        }
    } else {
        // 处理null或undefined作为EOS
        napi_valuetype valuetype;
        napi_typeof(env, args[0], &valuetype);
        if (valuetype == napi_null || valuetype == napi_undefined) {
            flags = AVCODEC_BUFFER_FLAGS_EOS;
            length = 0;
        } else {
            napi_throw_error(env, nullptr, "Expected Uint8Array, null or undefined for frame data");
            return nullptr;
        }
    }
    
    // 获取时间戳
    int64_t timestamp;
    napi_get_value_int64(env, args[1], &timestamp);
    
    // 调用解码
    bool success = g_decoderContext.decoder->decodeFrame(
        static_cast<uint8_t*>(bufferData), 
        length, 
        timestamp,
        flags  // 传递标志
    );
    
    // 返回结果
    napi_value result;
    napi_get_boolean(env, success, &result);
    return result;
}

// NAPI: 获取解码后的帧（同步）
static napi_value GetDecodedFrame(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (!g_decoderContext.decoder || !g_decoderContext.isInitialized) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }
    
    // 获取超时参数（可选）
    int32_t timeoutMs = 0;
    if (argc > 0) {
        napi_get_value_int32(env, args[0], &timeoutMs);
    }
    
    // 首先从内部队列获取
    VideoFramePtr frame = nullptr;
    {
        std::lock_guard<std::mutex> lock(g_decoderContext.queueMutex);
        if (!g_decoderContext.frameQueue.empty()) {
            frame = g_decoderContext.frameQueue.front();
            g_decoderContext.frameQueue.pop();
        }
    }
    
    // 如果队列中没有，尝试从解码器获取
    if (!frame) {
        frame = g_decoderContext.decoder->getDecodedFrame(timeoutMs);
    }
    
    if (!frame) {
        napi_value nullValue;
        napi_get_null(env, &nullValue);
        return nullValue;
    }
    
    // 创建 JavaScript 对象
    napi_value frameObj = CreateVideoFrameObject(env, frame);
    
    return frameObj;
}

// NAPI: 刷新解码器
static napi_value Flush(napi_env env, napi_callback_info info) {
    if (!g_decoderContext.decoder) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }
    
    g_decoderContext.decoder->flush();
    
    // 清理帧队列
    {
        std::lock_guard<std::mutex> lock(g_decoderContext.queueMutex);
        std::queue<VideoFramePtr> empty;
        std::swap(g_decoderContext.frameQueue, empty);
    }
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// NAPI: 启动解码器
static napi_value Start(napi_env env, napi_callback_info info) {
    if (!g_decoderContext.decoder) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }
    
    bool success = g_decoderContext.decoder->start();
    
    // 返回结果
    napi_value result;
    napi_get_boolean(env, success, &result);
    return result;
}

// NAPI: 停止解码器
static napi_value Stop(napi_env env, napi_callback_info info) {
    if (!g_decoderContext.decoder) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }
    
   g_decoderContext.decoder->stop();
    
    // 返回结果
     napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;

}

// NAPI: 释放解码器
static napi_value Release(napi_env env, napi_callback_info info) {
    FreeGlobalDecoder();
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

// NAPI: 获取解码器信息
static napi_value GetInfo(napi_env env, napi_callback_info info) {
    // 创建信息对象
    napi_value infoObj;
    napi_create_object(env, &infoObj);
    
    if (!g_decoderContext.decoder) {
        napi_value initializedValue;
        napi_get_boolean(env, false, &initializedValue);
        napi_set_named_property(env, infoObj, "initialized", initializedValue);
        
        napi_value startedValue;
        napi_get_boolean(env, false, &startedValue);
        napi_set_named_property(env, infoObj, "started", startedValue);
        
        napi_value surfaceModeValue;
        napi_get_boolean(env, false, &surfaceModeValue);
        napi_set_named_property(env, infoObj, "surfaceMode", surfaceModeValue);
        
        return infoObj;
    }
    
    // 宽度
    napi_value widthValue;
    napi_create_int32(env, g_decoderContext.decoder->getWidth(), &widthValue);
    napi_set_named_property(env, infoObj, "width", widthValue);
    
    // 高度
    napi_value heightValue;
    napi_create_int32(env, g_decoderContext.decoder->getHeight(), &heightValue);
    napi_set_named_property(env, infoObj, "height", heightValue);
    
    // 是否已初始化
    napi_value initializedValue;
    napi_get_boolean(env, g_decoderContext.isInitialized, &initializedValue);
    napi_set_named_property(env, infoObj, "initialized", initializedValue);
    
    // 是否已启动
    napi_value startedValue;
    napi_get_boolean(env, g_decoderContext.decoder->isStarted(), &startedValue);
    napi_set_named_property(env, infoObj, "started", startedValue);
    
    // 是否为 Surface 模式
    napi_value surfaceModeValue;
    napi_get_boolean(env, g_decoderContext.decoder->isSurfaceMode(), &surfaceModeValue);
    napi_set_named_property(env, infoObj, "surfaceMode", surfaceModeValue);
    
    return infoObj;
}

// NAPI: 检查格式支持
static napi_value IsSupported(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // 获取 MIME 类型
    char mimeType[256];
    size_t mimeTypeLength;
    napi_get_value_string_utf8(env, args[0], mimeType, sizeof(mimeType), &mimeTypeLength);
    
    // 检查支持
    bool supported = hmos_video_decoder_is_supported(mimeType);
    
    // 返回结果
    napi_value result;
    napi_get_boolean(env, supported, &result);
    return result;
}

// ==================== 模块初始化 ====================

// NAPI 模块初始化
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // 全局解码器方法
        { "initialize", nullptr, Initialize, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setSurface", nullptr, SetSurface, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "setCallbacks", nullptr, SetCallbacks, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "start", nullptr, Start, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "stop", nullptr, Stop, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "decodeFrame", nullptr, DecodeFrameTypedArray, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getDecodedFrame", nullptr, GetDecodedFrame, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "flush", nullptr, Flush, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "release", nullptr, Release, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getInfo", nullptr, GetInfo, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "isSupported", nullptr, IsSupported, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    LOGI("VideoDecoder NAPI module initialized (global decoder mode)");
    return exports;
}