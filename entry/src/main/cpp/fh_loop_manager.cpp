//
// Created by Vison on 2025/9/18.
//
#include <uv.h> // 必须包含头文件
#include "fh_loop_manager.h"
#include "napi/native_api.h"
#include "hmos_video_decoder.h"
#include <native_window/external_window.h> // 标准头文件路径
#include <sys/time.h>
#include <stdint.h>



/*#include "hmos_video_decoder.h"*/
#include <stdint.h>
#include <stdio.h>
#include <queue>
#include <hilog/log.h>
#include "UsbDataHeader.h"
#include "usb_loop_manager.h"
#include <unistd.h>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag
#define LOGD(fmt, ...) OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGI(fmt, ...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGE(fmt, ...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)


FHLoopManager &FHLoopManager::GetInstance() {
    static FHLoopManager instance;
    return instance;
}

napi_value FHLoopManager::createVideoStream(napi_env env, napi_callback_info type) {
    // 先销毁上次的句柄
    FHLoopManager::GetInstance().releaseVideoStream();

    // 1. 提取 ArkTS 传入的参数（期望 1 个整数）
    size_t argc = 1;
    napi_value args[1];
    napi_status status = napi_get_cb_info(env, type, &argc, args, nullptr, nullptr);
    // 2. 解析参数：ArkTS number → C++ int32_t
    int32_t inputNum;
    status = napi_get_value_int32(env, args[0], &inputNum);

    if (inputNum == 1) {
        FHLoopManager::GetInstance().myVideoLoopBufHandle = BLBDATA_Create(BLBDATA_TYPE_61_FRAME, 1024 * 500);
    } else if (inputNum == 2) {
        FHLoopManager::GetInstance().myVideoLoopBufHandle = BLBDATA_Create(BLBDATA_TYPE_62_FRAME, 1024 * 1024 * 10);
    } else if (inputNum == 4) {
        FHLoopManager::GetInstance().myVideoLoopBufHandle = BLBDATA_Create(BLBDATA_TYPE_62_FRAME, 1024 * 1024 * 20);
    } else if (inputNum == 5) {
        FHLoopManager::GetInstance().myVideoLoopBufHandle = BLBDATA_Create(BLBDATA_TYPE_63_FRAME, 1024 * 1024 * 10);
    } else {
        FHLoopManager::GetInstance().myVideoLoopBufHandle = BLBDATA_Create(BLBDATA_TYPE_81_FRAME, 1024 * 1024 * 10);
    }

    FHLoopManager::GetInstance().pVideoFrame = std::make_unique<char[]>(0x100000);

    napi_value result;

    if (!FHLoopManager::GetInstance().pVideoFrame) {       // 极端情况：内存分配失败
        FHLoopManager::GetInstance().releaseVideoStream(); // 回滚，释放已创建的底层缓冲区
        napi_get_boolean(env, false, &result);
        return result;
    }
    napi_get_boolean(env, true, &result);
    return result;
}

napi_value FHLoopManager::addVideoStream(napi_env env, napi_callback_info data) {

    // 1. 打印字符串（无参数）

    OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream 进入");
// LOG_APP表示应用日志类型，%{public}表示明文输出敏感信息
    // 1. 基础校验：句柄空/数据空/长度无效直接返回（上层已保证长度正确，仍做基础防护）
    if (FHLoopManager::GetInstance().myVideoLoopBufHandle == nullptr || data == nullptr) {
        OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream nullptr");
        return nullptr;
    }

    // 步骤 1：提取 ArkTS 传入的 2 个参数（视频流类型 + dataLength）
    size_t argc = 2; // 期望 2 个参数：num（int） + dataLength（jint）
    napi_value args[2];
    napi_status status = napi_get_cb_info(env, data, &argc, args, nullptr, nullptr);
    // 3. 解析第一个参数：Uint8Array
    napi_valuetype arrayType;
    status = napi_typeof(env, args[0], &arrayType);
    if (status != napi_ok || arrayType != napi_object) {
        OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream nullptr2");
        // 第一个参数必须是 Uint8Array
        return nullptr;
    }
    // 1. 获取Uint8Array的数据指针和长度
    uint8_t *jsData = nullptr;
    size_t dataLen = 0;
    napi_value arrayBuffer;
    size_t byteOffset;
    status = napi_get_typedarray_info(env, args[0],
                                      nullptr, // 类型（已验证是Uint8，忽略）
                                      &dataLen, reinterpret_cast<void **>(&jsData),
                                      &arrayBuffer, // 缓冲区（无需关心）
                                      &byteOffset   // 偏移量（默认0）
    );

    if (status != napi_ok) {
        OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream nullptr2--- ");
        return nullptr; // 类型校验失败处理
    }

    // 解析得到第二个数据长度
    int32_t inputNum;
    status = napi_get_value_int32(env, args[1], &inputNum);

    if (inputNum <= 0) {
        OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream nullptr3");
        return nullptr;
    }

    // 2. 分配C层缓冲区（关键：用智能指针自动释放，避免泄漏）
    std::unique_ptr<char[]> byteData(new char[inputNum]);

    // 拷贝数据到c层缓冲区
    memcpy(byteData.get(), jsData, inputNum); // 最稳定的拷贝方式

    // 3. 循环缓冲区操作：加锁→写数据→解锁（核心逻辑保留）
    int iRecvLen = inputNum;
    char *pLoopBuf1 = nullptr;
    int iLoopBufLen1 = 0;
    char *pLoopBuf2 = nullptr;
    int iLoopBufLen2 = 0;

    // BLBDATA_Lock(FHLoopManager::GetInstance().myVideoLoopBufHandle); // 加锁（确保线程安全）
    //  尝试获取写入指针
    if (BLBDATA_AdvGetWritePtr(FHLoopManager::GetInstance().myVideoLoopBufHandle, &pLoopBuf1,
                               (unsigned int *)&iLoopBufLen1, &pLoopBuf2, (unsigned int *)&iLoopBufLen2)) {
        // 分两种情况拷贝数据（与原逻辑完全一致）

        if (iLoopBufLen1 >= inputNum) {
            memcpy(pLoopBuf1, byteData.get(), iRecvLen);
        } else {
            memcpy(pLoopBuf1, byteData.get(), iLoopBufLen1);
            memcpy(pLoopBuf2, byteData.get() + iLoopBufLen1, iRecvLen - iLoopBufLen1);
        }
        // 更新写入位置
        BLBDATA_AdvSetWritePos(FHLoopManager::GetInstance().myVideoLoopBufHandle, iRecvLen);
        OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream 指针写入成功");
    }
    // BLBDATA_Unlock(FHLoopManager::GetInstance().myVideoLoopBufHandle);
    OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream 已走完");
    return nullptr;
}

/*
void FHLoopManager::addVideoStream872(napi_env env, napi_value data, jint dataLength) {
    if (myVideoLoopBufHandle == nullptr || data == nullptr || dataLength <= 0) {
        return;
    }

    std::unique_ptr<char[]> byteData(new char[dataLength]);
    //env->GetByteArrayRegion(data, 0, dataLength, reinterpret_cast<jbyte *>(byteData.get()));
      //拷贝数据到c层缓冲区
    memcpy(data,  byteData.get(), dataLength); // 最稳定的拷贝方式

    char *pLoopBuf1 = nullptr;
    int iLoopBufLen1 = 0;
    char *pLoopBuf2 = nullptr;
    int iLoopBufLen2 = 0;

    if (p872StreamBuf == nullptr) {
        p872StreamBuf = std::make_unique<char[]>(1024 * 1024);
        //static_cast<char *>(malloc(1024 * 1024));
    }

    // 解包872的数据封装
    char *tempBuffer = p872StreamBuf.get();
    int iRecvLen = analysis(dataLength, byteData.get(), tempBuffer);

    if (iRecvLen > 0) {
        BLBDATA_Lock(myVideoLoopBufHandle);   // lock
        if (BLBDATA_AdvGetWritePtr(myVideoLoopBufHandle, &pLoopBuf1,
                                   (unsigned int *) &iLoopBufLen1, &pLoopBuf2,
                                   (unsigned int *) &iLoopBufLen2)) {
            if (iLoopBufLen1 >= iRecvLen) {
                memcpy(pLoopBuf1, p872StreamBuf.get(), iRecvLen);
            } else {
                memcpy(pLoopBuf1, p872StreamBuf.get(), iLoopBufLen1);
                memcpy(pLoopBuf2, p872StreamBuf.get() + iLoopBufLen1, iRecvLen - iLoopBufLen1);
            }
            BLBDATA_AdvSetWritePos(myVideoLoopBufHandle, iRecvLen);
        }
        BLBDATA_Unlock(myVideoLoopBufHandle); // unlock
    }
}
*/


// 两个值 第一个是一帧的数据 第二个值是是否连续针
napi_value FHLoopManager::getVideoOneFrameArray(napi_env env, napi_callback_info header) {
    if (FHLoopManager::GetInstance().myVideoLoopBufHandle == nullptr || header == nullptr) {
        return nullptr;
    }

    FHNP_Dev_FrameHead_t stHead;


    if (!BLBDATA_GetOneFrame(FHLoopManager::GetInstance().myVideoLoopBufHandle, (char *)&stHead,
                             FHLoopManager::GetInstance().pVideoFrame.get(), 0)) {
       // OH_LOG_FATAL(LOG_APP, "帧数据 没有取到");
        return nullptr;
    }

    napi_value args[2];
    size_t argc = 2;
    // 2. 提取 ArkTS 传递的参数（数组）
    napi_status status = napi_get_cb_info(env, header, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Missing array parameter");
        return nullptr;
    }
    OH_LOG_FATAL(LOG_APP, "获取针数据22222");
    for (uint32_t i = 0; i < 7; ++i) {
        // 5.1 获取数组当前索引的元素（napi_value 类型）
        napi_value elem;
        status = napi_get_element(env, args[0], i, &elem);
        // 5.2 将 ArkTS 的 number 转为 C 的 int（可选：读取原数据）
        int32_t old_val;
        status = napi_get_value_int32(env, elem, &old_val);
        if (status == napi_ok) {
        }
        // 5.3 构造新值（示例：修改为 index*10）
        napi_value new_elem;
        int32_t new_val;
        if (i == 0) {
            new_val = stHead.frmnum;
        } else if (i == 1) {
            new_val = stHead.framelen;
        } else if (i == 2) {
            new_val = stHead.FrmHd[3];
        } else if (i == 3) {
            new_val = stHead.reserve[0];
        } else if (i == 4) {
            new_val = stHead.reserve[1];
        } else if (i == 5) {
            new_val = stHead.reserve[2];
        } else if (i == 6) {
            new_val = stHead.reserve[3];
        }
        status = napi_create_int32(env, new_val, &new_elem);
        if (status != napi_ok) {
            continue;
        }
        // 5.4 将新值写回数组（关键：直接修改原数组，ArkTS 侧同步生效）
        status = napi_set_element(env, args[0], i, new_elem);
    }
    bool etsBoolean = false; // 存储提取的布尔值（默认false）
    napi_valuetype argType;
    status = napi_get_value_bool(env, args[1], &etsBoolean);
    OH_LOG_FATAL(LOG_APP, "getVideoOneFrameArray_进入");
    // 检查帧连续性
    if (etsBoolean) {
        // 如果当前不是I帧且需要I帧跳过显示
        if (stHead.FrmHd[3] != 0xA1 && FHLoopManager::GetInstance().isNeedIFrame) {
            FHLoopManager::GetInstance().nowFrameIndex = stHead.frmnum;
            OH_LOG_FATAL(LOG_APP, "getVideoOneFrameArray_帧数据等待I帧---跳过---");
            return nullptr;
        }
        FHLoopManager::GetInstance().isNeedIFrame = false;

        // 检查帧是否连续，否则通知请求I帧
        if (FHLoopManager::GetInstance().nowFrameIndex + 1 != stHead.frmnum) {
            //  OH_LOG_FATAL(LOG_APP,"需要强制I帧");
            FHLoopManager::GetInstance().isNeedIFrame = true;
            // napi_value uint8_array = env->NewByteArray(5);

            napi_value array_buffer;
            void *buffer_ptr = nullptr;
            napi_status status = napi_create_arraybuffer(env, 5, &buffer_ptr, &array_buffer);
            if (status != napi_ok) {
                OH_LOG_FATAL(LOG_APP, "getVideoOneFrameArray_类型不对");
                napi_throw_error(env, nullptr, "Failed to create ArrayBuffer");
                OH_LOG_FATAL(LOG_APP, "getVideoOneFrameArray_类型不对");
                return nullptr;
            }
            return array_buffer;
        }

        FHLoopManager::GetInstance().nowFrameIndex = stHead.frmnum;

        if (FHLoopManager::GetInstance().nowFrameIndex >= 255) {
            FHLoopManager::GetInstance().nowFrameIndex = -1;
        }
    }
    int len = stHead.framelen;


    /* uint8_t fixedData[] = {1, 2, 3, 4, 5};
     size_t dataLength = sizeof(fixedData);*/

    napi_value array_buffer;
    void *buffer_ptr = nullptr;
    napi_status status1 = napi_create_arraybuffer(env, len, &buffer_ptr, &array_buffer);

    if (status1 != napi_ok || buffer_ptr == nullptr) {
        OH_LOG_ERROR(LOG_APP, "getVideoOneFrameArray_Failed to create ArrayBuffer");
        return nullptr; // 返回null而非无效array_buffer
    }

    // 复制数据到ArrayBuffer
    memcpy(buffer_ptr, FHLoopManager::GetInstance().pVideoFrame.get(), len);
    OH_LOG_ERROR(LOG_APP, "getVideoOneFrameArray_成功放回数据");
    return array_buffer;
}
static napi_value CreateFixedArrayBuffer(napi_env env, napi_callback_info info) {
    napi_value args[1];
    size_t argc = 1;
    // 2. 提取 ArkTS 传递的参数（数组）
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    // 定义固定数据（示例：5字节数据）
    uint8_t fixedData[] = {1, 2, 3, 4, 5};
    size_t dataLength = sizeof(fixedData);
    int32_t inputNum;
    status = napi_get_value_int32(env, args[0], &inputNum);

    // 创建ArrayBuffer
    void *bufferPtr = nullptr;
    napi_value arrayBuffer;
    napi_status status1 = napi_create_arraybuffer(env, dataLength, &bufferPtr, &arrayBuffer);
    if (status1 != napi_ok || bufferPtr == nullptr) {
        OH_LOG_ERROR(LOG_APP, "Failed to create ArrayBuffer");
        return nullptr;
    }

    // 复制固定数据到ArrayBuffer
    memcpy(bufferPtr, fixedData, dataLength);
    OH_LOG_INFO(LOG_APP, "ArrayBuffer created with length: %{public}zu", dataLength);
    return arrayBuffer;
}


/*jint FHLoopManager::getVideoOneFrameBuffer(napi_env env, jboolean check_continuity, napi_value buffer, napi_value
   header) {
    // 1. 校验输入参数有效性
    if (myVideoLoopBufHandle == nullptr || buffer == nullptr || header == nullptr) {
        return -1; // 无效参数
    }

    FHNP_Dev_FrameHead_t stHead;
    // 2. 获取一帧数据（pFrame为原有缓冲区，假设已初始化）
    if (!BLBDATA_GetOneFrame(myVideoLoopBufHandle, (char *) &stHead, pVideoFrame.get(), 0)) {
        return 0; // 无有效帧数据
    }

    //更新java层数据
  *//*  int *pHeader = env->GetIntArrayElements(header, 0);
    // 帧序号
    pHeader[0] = stHead.frmnum;
    // 帧长度
    pHeader[1] = stHead.framelen;
    // 帧类型
    pHeader[2] = stHead.FrmHd[3];
    pHeader[3] = stHead.reserve[0];
    pHeader[4] = stHead.reserve[1];
    pHeader[5] = stHead.reserve[2];
    pHeader[6] = stHead.reserve[3];

    //  OH_LOG_FATAL(LOG_APP,"校验数据--- %lu  %X  %X  %X  %X",sizeof(FHNP_Dev_FrameHead_t),stHead.reserve[0],stHead.reserve[1],stHead.reserve[2],stHead.reserve[3]);
    //通知更新
    env->ReleaseIntArrayElements(header, pHeader, 0);*//*

    // 检查帧连续性
    if (check_continuity) {
        // 如果当前不是I帧且需要I帧跳过显示
        if (stHead.FrmHd[3] != 0xA1 && isNeedIFrame) {
            nowFrameIndex = stHead.frmnum;
           //  OH_LOG_FATAL(LOG_APP,"等待I帧---跳过---");
            return 0; // 跳过非I帧
        }
        isNeedIFrame = false;

        // 检查帧是否连续，否则通知请求I帧
        if (nowFrameIndex + 1 != stHead.frmnum) {
           //  OH_LOG_FATAL(LOG_APP,"需要强制I帧");
            isNeedIFrame = true;
            return 5; // 特殊标记：需要请求I帧（对应原逻辑的5字节数组）
        }
        nowFrameIndex = stHead.frmnum;

        if (nowFrameIndex >= 255) {
            nowFrameIndex = -1;
        }
    }
    //  复用传入的buffer存储帧数据
    int frameLen = stHead.framelen;
   *//* jbyte *bufferPtr = env->GetByteArrayElements(buffer, nullptr);
    if (bufferPtr == nullptr) {
        return -2; // 内存获取失败
    }

    //  复制帧数据到buffer（覆盖旧数据）
    memcpy(bufferPtr, pVideoFrame.get(), frameLen);*//*
   // env->ReleaseByteArrayElements(buffer, bufferPtr, 0);

    //  返回实际帧长度（Java层用此长度处理有效数据）
    return frameLen;
}*/

void FHLoopManager::releaseVideoStream() {
    if (myVideoLoopBufHandle != nullptr) {
        BLBDATA_Clear(myVideoLoopBufHandle);
        BLBDATA_Destory(myVideoLoopBufHandle);
        myVideoLoopBufHandle = nullptr;
    }

    if (p872StreamBuf != nullptr) {
        p872StreamBuf.reset();
    }

    if (pVideoFrame != nullptr) {
        pVideoFrame.reset();
    }

    nowFrameIndex = 0;
    isNeedIFrame = true;
}

/*bool FHLoopManager::createAudioStream() {
    releaseAudioStream();
    myAudioLoopBufHandle = BLBDATA_Create(BLBDATA_TYPE_62_FRAME, 1024 * 500);
    pAudioFrame = std::make_unique<char[]>(0x80000); // 512KB

    if (!pAudioFrame) {  // 极端情况：内存分配失败
        releaseAudioStream();  // 回滚，释放已创建的底层缓冲区
        return false;
    }
    return true;
}*/
/*
void FHLoopManager::addAudioStream(napi_env env, napi_value data, int dataLength) {
    if (myAudioLoopBufHandle == nullptr) {
        return;
    }

    std::unique_ptr<char[]> byteData(new char[dataLength]);
    //env->GetByteArrayRegion(data, 0, dataLength, reinterpret_cast<jbyte *>(byteData.get()));

    int iRecvLen = dataLength;
    char *pLoopBuf1 = nullptr;
    int iLoopBufLen1 = 0;
    char *pLoopBuf2 = nullptr;
    int iLoopBufLen2 = 0;

    if (iRecvLen > 0) {
        BLBDATA_Lock(myAudioLoopBufHandle);   // lock
        if (BLBDATA_AdvGetWritePtr(myAudioLoopBufHandle, &pLoopBuf1,
                                   (unsigned int *) &iLoopBufLen1, &pLoopBuf2,
                                   (unsigned int *) &iLoopBufLen2)) {
            if (iLoopBufLen1 >= iRecvLen) {
                memcpy(pLoopBuf1, byteData.get(), iRecvLen);
            } else {
                memcpy(pLoopBuf1, byteData.get(), iLoopBufLen1);
                memcpy(pLoopBuf2, byteData.get() + iLoopBufLen1, iRecvLen - iLoopBufLen1);
            }
            BLBDATA_AdvSetWritePos(myAudioLoopBufHandle, iRecvLen);
        }
        BLBDATA_Unlock(myAudioLoopBufHandle); // unlock
    }
}*/

/*napi_value FHLoopManager::getAudioOneFrame(napi_env env) {
    if (myAudioLoopBufHandle == nullptr) {
        return nullptr;
    }
        *//*
        * stHead.frmnum 0~255
        * stHead.FrmHd[3] == 0xA1 I frame
        *//*
    FHNP_Dev_FrameHead_t stHead;
    if (!BLBDATA_GetOneFrame(myAudioLoopBufHandle, (char *) &stHead, pAudioFrame.get(), 0)) {
        return nullptr;
    }

    int len = stHead.framelen;
  *//*  napi_value jbyteArray = napi_create_uint8array(env, len, nullptr, &jbyteArray)
    env->SetByteArrayRegion(jbyteArray, 0, len, reinterpret_cast<const jbyte *>(pAudioFrame.get()));*//*
     napi_value jbyteArray ;
    return jbyteArray;
}*/

/*napi_value CreateByteArray(napi_env env, size_t len) {
    void* buffer = nullptr;
    napi_value arrayBuffer;
    napi_create_arraybuffer(env, len, &buffer, &arrayBuffer); // 创建 ArrayBuffer
    return arrayBuffer;
}*/


void FHLoopManager::releaseAudioStream() {
    if (myAudioLoopBufHandle != nullptr) {
        BLBDATA_Clear(myAudioLoopBufHandle);
        BLBDATA_Destory(myAudioLoopBufHandle);
        myAudioLoopBufHandle = nullptr;
    }

    if (pAudioFrame != nullptr) {
        pAudioFrame.reset();
    }
}


static napi_value Add(napi_env env, napi_callback_info info) {


    OH_LOG_FATAL(LOG_APP, "Failed to visit path.");
// 设置应用日志最低打印级别，设置完成后，低于Warn级别的日志将无法打印
    OH_LOG_SetMinLogLevel(LOG_INFO);
    OH_LOG_FATAL(LOG_APP, "this is an info level log");
    OH_LOG_FATAL(LOG_APP, "this is an error level log");
// 设置应用日志PREFER_OPEN_LOG策略的最低打印级别，设置完成后，不低于INFO级别的日志都可打印
    //  OH_LOG_SetLogLevel(LOG_WARN);
    OH_LOG_FATAL(LOG_APP, "this is an another info level log");
    OH_LOG_FATAL(LOG_APP, "this is an another error level log");


    size_t argc = 2;
    napi_value args[2] = {nullptr};

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    napi_valuetype valuetype0;
    napi_typeof(env, args[0], &valuetype0);

    napi_valuetype valuetype1;
    napi_typeof(env, args[1], &valuetype1);

    double value0;
    napi_get_value_double(env, args[0], &value0);

    double value1;
    napi_get_value_double(env, args[1], &value1);

    napi_value sum;
    napi_create_double(env, value0 + value1, &sum);


    return sum;
}

// 解码相关
//  全局解码器上下文
static struct {
    HmosVideoDecoder *decoder = nullptr;
    bool isInitialized = false;
    // 回调引用
    napi_ref frameCallbackRef = nullptr;
    napi_ref errorCallbackRef = nullptr;
    napi_ref formatChangedCallbackRef = nullptr;

    // 线程安全队列（使用智能指针）
    std::queue<VideoFramePtr> frameQueue;
    std::mutex queueMutex;

    // 当前环境
    napi_env currentEnv = nullptr;
} g_decoderContext;

// 创建视频帧对象
static napi_value CreateVideoFrameObject(napi_env env, const VideoFramePtr &frame) {
    napi_value result;
    napi_create_object(env, &result);

    if (!frame) {
        return result;
    }

    // 创建 ArrayBuffer 存储帧数据
    napi_value arrayBuffer;
    size_t totalSize = frame->data.size();

    void *data = nullptr;
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

// 1. 定义回调数据结构
struct FrameCallbackData {
    VideoFramePtr frame;
};

// 帧回调包装函数
static void OnFrameCallbackWrapper(VideoFramePtr frame) {
    if (!frame) {
        return;
    }

    // 如果有回调函数，在 JavaScript 主线程调用
    if (g_decoderContext.frameCallbackRef && g_decoderContext.currentEnv) {
        napi_handle_scope scope;
        napi_open_handle_scope(g_decoderContext.currentEnv, &scope);

        // 获取回调函数
        napi_value callback;
        napi_get_reference_value(g_decoderContext.currentEnv, g_decoderContext.frameCallbackRef, &callback);

        // 创建帧对象
        napi_value frameObj = CreateVideoFrameObject(g_decoderContext.currentEnv, frame);


        // 调用回调
        napi_value result;
        napi_call_function(g_decoderContext.currentEnv, nullptr, callback, 1, &frameObj, &result);


        napi_close_handle_scope(g_decoderContext.currentEnv, scope);
    } else {
        // 如果没有回调，将帧加入队列供同步获取
        std::lock_guard<std::mutex> lock(g_decoderContext.queueMutex);
        g_decoderContext.frameQueue.push(frame);
    }
}

// 错误回调包装函数
static void OnErrorCallbackWrapper(int32_t errorCode) {
    if (!g_decoderContext.errorCallbackRef || !g_decoderContext.currentEnv) {
        return;
    }

    napi_handle_scope scope;
    napi_open_handle_scope(g_decoderContext.currentEnv, &scope);

    // 获取回调函数
    napi_value callback;
    napi_get_reference_value(g_decoderContext.currentEnv, g_decoderContext.errorCallbackRef, &callback);

    // 创建错误码参数
    napi_value errorValue;
    napi_create_int32(g_decoderContext.currentEnv, errorCode, &errorValue);

    // 调用回调
    napi_value result;
    napi_call_function(g_decoderContext.currentEnv, nullptr, callback, 1, &errorValue, &result);

    napi_close_handle_scope(g_decoderContext.currentEnv, scope);
}

// 格式变更回调包装函数
static void OnFormatChangedCallbackWrapper(int32_t width, int32_t height, int32_t format) {
    if (!g_decoderContext.formatChangedCallbackRef || !g_decoderContext.currentEnv) {
        return;
    }

    napi_handle_scope scope;
    napi_open_handle_scope(g_decoderContext.currentEnv, &scope);

    // 获取回调函数
    napi_value callback;
    napi_get_reference_value(g_decoderContext.currentEnv, g_decoderContext.formatChangedCallbackRef, &callback);

    // 创建参数对象
    napi_value formatObj;
    napi_create_object(g_decoderContext.currentEnv, &formatObj);

    napi_value widthValue;
    napi_create_int32(g_decoderContext.currentEnv, width, &widthValue);
    napi_set_named_property(g_decoderContext.currentEnv, formatObj, "width", widthValue);

    napi_value heightValue;
    napi_create_int32(g_decoderContext.currentEnv, height, &heightValue);
    napi_set_named_property(g_decoderContext.currentEnv, formatObj, "height", heightValue);

    napi_value formatValue;
    napi_create_int32(g_decoderContext.currentEnv, format, &formatValue);
    napi_set_named_property(g_decoderContext.currentEnv, formatObj, "format", formatValue);

    if (g_decoderContext.currentEnv) {
        // 调用回调
        napi_value result;
        // napi_call_function(g_decoderContext.currentEnv, nullptr, callback, 1, &formatObj, &result);
    }
    napi_close_handle_scope(g_decoderContext.currentEnv, scope);
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


// NAPI: 启动解码器
static napi_value Start(napi_env env, napi_callback_info info) {
    if (!g_decoderContext.decoder) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }

    bool result = g_decoderContext.decoder->start();

    napi_value resultValue;
    napi_get_boolean(env, result, &resultValue);
    return resultValue;
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

    // 1. 从ArkTS获取surfaceId（bigint类型）
    uint64_t surfaceId = 0;
    bool lossless = false;

    // 检查参数类型是否为bigint
    napi_valuetype valuetype;
    napi_typeof(env, args[0], &valuetype);
    if (valuetype == napi_bigint) {
        // 从bigint获取uint64_t值
        napi_get_value_bigint_uint64(env, args[0], &surfaceId, &lossless);
        LOGI("SetSurface: 接收到surfaceId = %llu", surfaceId);
    } else if (valuetype == napi_number) {
        // 如果传递的是普通数字，也尝试转换
        int32_t tempSurfaceId = 0;
        napi_get_value_int32(env, args[0], &tempSurfaceId);
        surfaceId = static_cast<uint64_t>(tempSurfaceId);
        LOGI("SetSurface: 接收到数字surfaceId = %llu", surfaceId);
    } else {
        napi_throw_error(env, nullptr, "参数必须是bigint或number类型");
        return nullptr;
    }

    if (surfaceId == 0) {
        napi_throw_error(env, nullptr, "无效的surfaceId");
        return nullptr;
    }

    // 2. 使用surfaceId创建NativeWindow
    OHNativeWindow *nativeWindow = nullptr;
    int32_t ret = OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow);
    LOGE("SetSurface: 创建NativeWindow失败，错误码: %{public}d, surfaceId: %{public}llu", ret, surfaceId);


    // 设置Surface
    bool success = g_decoderContext.decoder->setSurface(static_cast<OHNativeWindow *>(nativeWindow));

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
    if (!g_decoderContext.decoder) {
        OH_LOG_ERROR(LOG_APP, "解码一帧数据=解码器未初始化");
        // 返回结果
        napi_value result;
        napi_get_boolean(env, false, &result);
        return result;
    }

    size_t argc = 3;
    napi_value args[3];

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 2) {
        OH_LOG_ERROR(LOG_APP, "解码一帧数据=argc<2");
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }

    if (!g_decoderContext.decoder || !g_decoderContext.isInitialized) {
        OH_LOG_ERROR(LOG_APP, "解码一帧数据=Decoder not initialized");
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }

    // 获取数据参数
    bool isTypedArray;
    napi_is_typedarray(env, args[0], &isTypedArray);

    void *bufferData = nullptr;
    size_t length = 0;
    uint32_t flags = AVCODEC_BUFFER_FLAGS_SYNC_FRAME | AVCODEC_BUFFER_FLAGS_CODEC_DATA;
    OH_LOG_ERROR(LOG_APP, "解码一帧数据=%{public}s", isTypedArray ? "yes" : "no");
    // 获取第三个数据 是否i帧
    bool isI = false; // 存储提取的布尔值（默认false）

    napi_status status = napi_get_value_bool(env, args[2], &isI);
    OH_LOG_ERROR(LOG_APP, "解码一帧数据= 是否关键帧%{public}s", isI ? "yes" : "no");
    if (isTypedArray) {
        napi_typedarray_type type;
        napi_value buffer;

        napi_get_typedarray_info(env, args[0], &type, &length, &bufferData, &buffer, nullptr);

        if (type != napi_uint8_array) {
            OH_LOG_ERROR(LOG_APP, "解码一帧数据=类型不对");
            return nullptr;
        }

        if (isI) {
            flags = AVCODEC_BUFFER_FLAGS_SYNC_FRAME;
        } else {
            flags = AVCODEC_BUFFER_FLAGS_NONE;
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
            OH_LOG_ERROR(LOG_APP, "解码一帧数据=null or undefined for frame data");
            return nullptr;
        }
    }

    // 获取时间戳
    int64_t timestamp;
     napi_status status1 = napi_get_value_int64(env, args[1], &timestamp);
    if (status != napi_ok) {
        LOGI("int64位数据接受失败%{public}PRId64",status1);
        return nullptr;
    }
    
     struct timeval tv;
    gettimeofday(&tv, NULL);
    timestamp = (uint64_t)tv.tv_sec * 1000000 + tv.tv_usec;

    
    
    LOGI("时间戳数据C层, timestamp=%{public}lld,", timestamp);
    // 调用解码
    bool success = g_decoderContext.decoder->decodeFrame(static_cast<uint8_t *>(bufferData), length, timestamp,
                                                         flags // 传递标志
    );


    // 返回结果
    napi_value result;
    napi_get_boolean(env, success, &result);
    OH_LOG_ERROR(LOG_APP, "解码一帧数据=null 走完");
    return result;
}

static uint64_t get_microsecond_epoch_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint64_t)tv.tv_sec * 1000000 + tv.tv_usec;
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

// NAPI: 停止解码器
static napi_value Stop(napi_env env, napi_callback_info info) {
    if (!g_decoderContext.decoder) {
        napi_throw_error(env, nullptr, "Decoder not initialized");
        return nullptr;
    }

    g_decoderContext.decoder->stop();

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


/*
usb环形buff相关
*/
LBUFHANDLE myUsbLoopBufDataHandle; // usb环形buff

static napi_value createUsbStream(napi_env env, napi_callback_info info) {
    myUsbLoopBufDataHandle = LBUF_Create(1024 * 1024 * 20);
    return nullptr;
}

static napi_value addUsbStream(napi_env env, napi_callback_info info) {
// Java_com_vison_sdk_VNDK_addUsbStream(JNIEnv *env, jclass clazz, jbyteArray data, jint data_length) {
    if (myUsbLoopBufDataHandle == nullptr) {
        OH_LOG_FATAL(LOG_APP, "addUsb错误 myUsbLoopBufDataHandle is null");
        return nullptr;
    }

    /*   if (data == nullptr || data_length <= 0) {
           LOGE("Invalid data or data_length");
           return;
       }*/
    // 步骤 1：提取 ArkTS 传入的 2 个参数（视频流类型 + dataLength）
    size_t argc = 2; // 期望 2 个参数：num（int） + dataLength（jint）
    napi_value args[2];
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    // 3. 解析第一个参数：Uint8Array
    napi_valuetype arrayType;
    status = napi_typeof(env, args[0], &arrayType);
    if (status != napi_ok || arrayType != napi_object) {
        OH_LOG_FATAL(LOG_APP, "addUsb错误 nullptr2");
        // 第一个参数必须是 Uint8Array
        return nullptr;
    }
    // 1. 获取Uint8Array的数据指针和长度
    uint8_t *jsData = nullptr;
    size_t dataLen = 0;
    napi_value arrayBuffer;
    size_t byteOffset;
    status = napi_get_typedarray_info(env, args[0],
                                      nullptr, // 类型（已验证是Uint8，忽略）
                                      &dataLen, reinterpret_cast<void **>(&jsData),
                                      &arrayBuffer, // 缓冲区（无需关心）
                                      &byteOffset   // 偏移量（默认0）
    );

    if (status != napi_ok) {
        return nullptr; // 类型校验失败处理
    }

// 解析得到第二个数据长度
    int32_t inputNum;
    status = napi_get_value_int32(env, args[1], &inputNum);

    if (inputNum <= 0) {
        OH_LOG_FATAL(LOG_APP, "addUsb错误 nullptr3");
        return nullptr;
    }


    // 使用智能指针管理C层缓冲区（自动释放，避免泄漏）
    std::unique_ptr<char[]> byteData(new char[inputNum]);

    // 从Java数组拷贝数据到C层缓冲区
    memcpy(byteData.get(), jsData, inputNum); // 最稳定的拷贝方式

    // LOGE("VNDK_addUsbStream byteData create length = %d , data_length = %d",length,data_length);
    int iRecvLen = inputNum;
    LBUF_Lock(myUsbLoopBufDataHandle);
    LBUF_Write(myUsbLoopBufDataHandle, byteData.get(), iRecvLen);
    LBUF_Unlock(myUsbLoopBufDataHandle);
    OH_LOG_FATAL(LOG_APP, "addUsb错误  已走完");
    return nullptr;
}


static napi_value getUsbOneFrame(napi_env env, napi_callback_info info) {
// Java_com_vison_sdk_VNDK_getUsbOneFrame(JNIEnv *env, jclass clazz, jintArray header) {
    if (myUsbLoopBufDataHandle == nullptr) {
        //  OH_LOG_FATAL(LOG_APP, "Usb错误_---myUsbLoopBufDataHandle为空");
        return nullptr;
    }

    LBUF_Lock(myUsbLoopBufDataHandle);
    unsigned int readLen = 11;
    // 用智能指针管理frameData，自动释放
    std::unique_ptr<char, decltype(&free)> frameData(static_cast<char *>(malloc(11)), free);

    if (!frameData || !LBUF_Read(myUsbLoopBufDataHandle, frameData.get(), &readLen)) {
        LBUF_Unlock(myUsbLoopBufDataHandle);
        return nullptr;
    }
    LBUF_Unlock(myUsbLoopBufDataHandle);
    for (int i = 0; i < 11; i++) {
        //  OH_LOG_FATAL(LOG_APP, "Usb错误_frameData i= %{public}d data= %{public}d",i,frameData.get()[i]);
    }

    if (frameData.get()[0] == 0xff && frameData.get()[1] == 0x56 && frameData.get()[2] == 0x53) {
        uint16_t check;
        memcpy(&check, &frameData.get()[9], 2);
        uint16_t length = 0;
        uint16_t length1 = 0;

        if (check == 0) {
            length = 501;
            memcpy(&length1, &frameData.get()[5], 2);
        } else {
            memcpy(&length, &frameData.get()[5], 2);
        }

        if (length > 0) {
            // 用智能指针管理frameData1，自动释放
            std::unique_ptr<char, decltype(&free)> frameData1(static_cast<char *>(malloc(length)), free);
            if (!frameData1) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 malloc frameData1失败");
                return nullptr;
            }
            // 修复锁未成对释放问题
            bool readSuccess = false;
            while (true) {
                LBUF_Lock(myUsbLoopBufDataHandle);
                if (LBUF_Read1(myUsbLoopBufDataHandle, frameData1.get(), &length)) {
                    LBUF_Unlock(myUsbLoopBufDataHandle); // 成功后立即解锁
                    readSuccess = true;
                    break;
                } else {
                    LBUF_Unlock(myUsbLoopBufDataHandle); // 失败也解锁
                    usleep(1000);
                    continue;
                }
            }


            if (!readSuccess) {
                OH_LOG_FATAL(LOG_APP, "Usb错误  读取frameData1失败");
                return nullptr;
            }

            if (check == 0) {
                length = length1;
            }

            // 用智能指针管理frameData2，自动释放
            std::unique_ptr<char, decltype(&free)> frameData2(static_cast<char *>(malloc(length + 11)), free);
            if (!frameData2) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 malloc frameData2失败");
                return nullptr;
            }

            memcpy(frameData2.get(), frameData.get(), 11);
            memcpy(frameData2.get() + 11, frameData1.get(), length);
            // 增加header拷贝越界校验
            if (length + 11 < 3 + 8) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 数据长度不足，无法解析header");
                return nullptr;
            }
            UsbDataHeader_2 frame;
            memcpy(&frame, frameData2.get() + 3, 8);

            if (frame.msgid > 20 || frame.len == 0) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 错误数据 %d", frame.order);
                return nullptr; // 智能指针自动释放资源
            }
            // 增加buf拷贝越界校验
            if (frame.len > length) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 frame.len(%d)超过实际数据长度(%d)", frame.len, length);
                return nullptr;
            }

            // 用智能指针管理frame.buf
            std::unique_ptr<unsigned char, decltype(&free)> frameBuf(static_cast<unsigned char *>(malloc(frame.len)),
                                                                     free);
            if (!frameBuf) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 malloc frameBuf失败");
                return nullptr;
            }
            memcpy(frameBuf.get(), frameData2.get() + 3 + 8, frame.len);

            int len = frame.len;


            napi_value args[1];
            size_t argc = 1;
            // 2. 提取 ArkTS 传递的参数（数组）
            napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
            if (status != napi_ok || argc < 1) {
                OH_LOG_FATAL(LOG_APP, "Usb错误 类型不对");
                napi_throw_error(env, nullptr, "Usb错误 Missing array parameter");
                return nullptr;
            }
            for (uint32_t i = 0; i < 3; ++i) {
                // 5.1 获取数组当前索引的元素（napi_value 类型）
                napi_value elem;
                status = napi_get_element(env, args[0], i, &elem);
                // 5.2 将 ArkTS 的 number 转为 C 的 int（可选：读取原数据）
                int32_t old_val;
                status = napi_get_value_int32(env, elem, &old_val);
                if (status == napi_ok) {
                }
                // 5.3 构造新值（示例：修改为 index*10）
                napi_value new_elem;
                int32_t new_val;
                if (i == 0) {
                    new_val = frame.order;
                } else if (i == 1) {
                    new_val = len;
                } else if (i == 2) {
                    new_val = frame.msgid;
                }
                status = napi_create_int32(env, new_val, &new_elem);
                if (status != napi_ok) {
                    continue;
                }
                // 5.4 将新值写回数组（关键：直接修改原数组，ArkTS 侧同步生效）
                status = napi_set_element(env, args[0], i, new_elem);
            }
            /*   jbyteArray jbyteArray = env->NewByteArray(len);
               env->SetByteArrayRegion(jbyteArray, 0, len, reinterpret_cast<const jbyte *>(frameBuf.get()));*/
            napi_value array_buffer;
            void *buffer_ptr = nullptr;
            napi_status status1 = napi_create_arraybuffer(env, len, &buffer_ptr, &array_buffer);
            if (status1 != napi_ok || buffer_ptr == nullptr) {
                OH_LOG_ERROR(LOG_APP, "Usb错误 Failed to create ArrayBuffer");
                return nullptr; // 返回null而非无效array_buffer
            }
            // 复制数据到ArrayBuffer
            memcpy(buffer_ptr, frameBuf.get(), len);
            return array_buffer;
        }
    }
    // 所有智能指针在函数退出时自动释放
    OH_LOG_ERROR(LOG_APP, "Usb错误 已走完");
    return nullptr;
}


// NAPI: 开始录制
static napi_value StreamRecording(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t fd = -1;
    napi_get_value_int32(env, args[0], &fd);
    OH_LOG_INFO(LOG_APP, "[C++] Received FD: %{public}d", fd);
    
    if (fd < 0) {
        OH_LOG_ERROR(LOG_APP, "[C++] Invalid FD");
        napi_throw_error(env, nullptr, "Invalid FD");
        return nullptr;
    }
     // 检查是否为对象
    napi_valuetype type;
    napi_typeof(env, args[1], &type);
    if (type != napi_object) {
        napi_throw_error(env, nullptr, "Argument must be an object { width, height }");
        return nullptr;
    }

    // 获取 width 和 height 属性
    napi_value width_val, height_val;
    napi_get_named_property(env, args[1], "width", &width_val);
    napi_get_named_property(env, args[1], "height", &height_val);

    int32_t width, height;
    napi_get_value_int32(env, width_val, &width);
    napi_get_value_int32(env, height_val, &height);
    

    //需要接受一个路径传递过去
    g_decoderContext.decoder->StreamRecording(fd,width,height);

 
    return nullptr;
}

// NAPI: 停止录制
static napi_value StopRecording(napi_env env, napi_callback_info info) {
    g_decoderContext.decoder->StopRecording();
    return nullptr;
}


EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // wifi视频流处理方法
        {"add", nullptr, Add, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"createVideoStream", nullptr, FHLoopManager::createVideoStream, nullptr, nullptr, nullptr, napi_default,
         nullptr},
        {"addVideoStream", nullptr, FHLoopManager::addVideoStream, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getVideoOneFrameArray", nullptr, FHLoopManager::getVideoOneFrameArray, nullptr, nullptr, nullptr,
         napi_default, nullptr},
        {"CreateFixedArrayBuffer", nullptr, CreateFixedArrayBuffer, nullptr, nullptr, nullptr, napi_default, nullptr},
        // 全局解码器方法
        {"initialize", nullptr, Initialize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"start", nullptr, Start, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setSurface", nullptr, SetSurface, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"setCallbacks", nullptr, SetCallbacks, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"decodeFrame", nullptr, DecodeFrameTypedArray, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getDecodedFrame", nullptr, GetDecodedFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"flush", nullptr, Flush, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"stop", nullptr, Stop, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"release", nullptr, Release, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getInfo", nullptr, GetInfo, nullptr, nullptr, nullptr, napi_default, nullptr},
        // usb数据处理方法
        {"createUsbStream", nullptr, createUsbStream, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"addUsbStream", nullptr, addUsbStream, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"getUsbOneFrame", nullptr, getUsbOneFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        // 录制方法
        {"StreamRecording", nullptr, StreamRecording, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"StopRecording", nullptr, StopRecording, nullptr, nullptr, nullptr, napi_default, nullptr},

    };


    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { napi_module_register(&demoModule); }
