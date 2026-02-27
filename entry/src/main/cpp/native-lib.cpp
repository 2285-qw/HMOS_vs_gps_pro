
#include <string>
#include <queue>
#include "BLoopBufData.h"
#include "UsbLoopBufData.h"
#include "NetProtocol.h"
// #include "UsbDataHeader.h"
#include "LogUtils.h"

#include <unistd.h>
#include "_872Stream.h"

#include <mutex>

#include "NetProtocol8620.h"
#include "LoopBuf.h"
/*#include "srt_receiver_manager.h"*/
#include "UsbDataHeader.h"
#include "usb_loop_manager.h"

#include "fh_loop_manager.h"
#include <hilog/log.h>
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag


//
// Created by Administrator on 2021/5/24 0024.
//


LBUFHANDLE my1UsbLoopBufDataHandle; // usb环形buff


/*bool isDecoding; // 是否解码中*/


extern "C"

// Java_com_vison_sdk_VNDK_getVersion(JNIEnv *env, jclass clazz) {
//     std::string version = "1.1.8";
//     LOGI("ffmpeg version=%s", av_version_info());
//     return env->NewStringUTF(version.c_str());
// }
//
// extern "C"
//
// Java_com_vison_sdk_VNDK_createVideoStream(JNIEnv *env, jclass clazz, jint type) {
//     bool isCreate = FHLoopManager::GetInstance().createVideoStream(type);
//
// }
//
// extern "C"
//
// Java_com_vison_sdk_VNDK_createAudioStream(JNIEnv *env, jclass clazz) {
//     bool isCreate = FHLoopManager::GetInstance().createAudioStream();
//     LOGD("createAudioStream %d",isCreate);
// }
//
// extern "C"

napi_value createUsbStream(napi_env env, napi_callback_info info) {
    my1UsbLoopBufDataHandle = LBUF_Create(1024 * 1024 * 20);
}
//
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_addVideoStream(JNIEnv *env, jclass clazz, jbyteArray data, jint data_length) {
//    FHLoopManager::GetInstance().addVideoStream(env,data,data_length);
//}
//
// extern "C"
// JNIEXPORT void JNICALL
napi_value addUsbStream(napi_env env, napi_callback_info info) {
// Java_com_vison_sdk_VNDK_addUsbStream(JNIEnv *env, jclass clazz, jbyteArray data, jint data_length) {
    if (my1UsbLoopBufDataHandle == nullptr) {
        OH_LOG_FATAL(LOG_APP, "USB my1UsbLoopBufDataHandle is null");
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
        return nullptr; // 类型校验失败处理
    }

// 解析得到第二个数据长度
    int32_t inputNum;
    status = napi_get_value_int32(env, args[1], &inputNum);

    if (inputNum <= 0) {
        OH_LOG_FATAL(LOG_APP, "帧数据_addVideoStream nullptr3");
        return nullptr;
    }


    // 使用智能指针管理C层缓冲区（自动释放，避免泄漏）
    std::unique_ptr<char[]> byteData(new char[inputNum]);

    // 从Java数组拷贝数据到C层缓冲区
    memcpy(byteData.get(), jsData, inputNum); // 最稳定的拷贝方式

    // LOGE("VNDK_addUsbStream byteData create length = %d , data_length = %d",length,data_length);
    int iRecvLen = inputNum;
    LBUF_Lock(my1UsbLoopBufDataHandle);
    LBUF_Write(my1UsbLoopBufDataHandle, byteData.get(), iRecvLen);
    LBUF_Unlock(my1UsbLoopBufDataHandle);
}
//
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_addAudioStream(JNIEnv *env, jclass clazz, jbyteArray data, jint data_length) {
//    FHLoopManager::GetInstance().addAudioStream(env,data,data_length);
//}
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_add872Stream(JNIEnv *env, jclass clazz, jbyteArray data, jint data_length) {
//    FHLoopManager::GetInstance().addVideoStream872(env,data,data_length);
//}
//
// extern "C"
// JNIEXPORT jbyteArray JNICALL
// Java_com_vison_sdk_VNDK_getVideoOneFrameArray(JNIEnv *env, jclass clazz, jboolean check_continuity, jintArray header) {
//    return FHLoopManager::GetInstance().getVideoOneFrameArray(env,check_continuity,header);
//}
//
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_getVideoOneFrameBuffer(JNIEnv *env, jclass clazz, jboolean check_continuity, jbyteArray buffer, jintArray header) {
//    return FHLoopManager::GetInstance().getVideoOneFrameBuffer(env,check_continuity,buffer,header);
//}
//
// extern "C"
// JNIEXPORT jbyteArray JNICALL
// Java_com_vison_sdk_VNDK_getAudioOneFrame(JNIEnv *env, jclass clazz) {
//    return FHLoopManager::GetInstance().getAudioOneFrame(env);
//}
//
//
// extern "C"
/*napi_value getUsbOneFrame(napi_env env, napi_callback_info info) {
// Java_com_vison_sdk_VNDK_getUsbOneFrame(JNIEnv *env, jclass clazz, jintArray header) {
    if (my1UsbLoopBufDataHandle == nullptr) {
        return nullptr;
    }

    LBUF_Lock(my1UsbLoopBufDataHandle);
    unsigned int readLen = 11;
    // 用智能指针管理frameData，自动释放
    std::unique_ptr<char, decltype(&free)> frameData(static_cast<char *>(malloc(11)), free);
    if (!frameData || !LBUF_Read(my1UsbLoopBufDataHandle, frameData.get(), &readLen)) {
        LBUF_Unlock(my1UsbLoopBufDataHandle);
        return nullptr;
    }
    LBUF_Unlock(my1UsbLoopBufDataHandle);

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
                OH_LOG_FATAL(LOG_APP, "malloc frameData1失败");
                return nullptr;
            }

            // 修复锁未成对释放问题
            bool readSuccess = false;
            while (true) {
                LBUF_Lock(my1UsbLoopBufDataHandle);
                if (LBUF_Read1(my1UsbLoopBufDataHandle, frameData1.get(), &length)) {
                    LBUF_Unlock(my1UsbLoopBufDataHandle); // 成功后立即解锁
                    readSuccess = true;
                    break;
                } else {
                    LBUF_Unlock(my1UsbLoopBufDataHandle); // 失败也解锁
                    usleep(1000);
                    continue;
                }
            }

            if (!readSuccess) {
                OH_LOG_FATAL(LOG_APP, "读取frameData1失败");
                return nullptr;
            }

            if (check == 0) {
                length = length1;
            }

            // 用智能指针管理frameData2，自动释放
            std::unique_ptr<char, decltype(&free)> frameData2(static_cast<char *>(malloc(length + 11)), free);
            if (!frameData2) {
                OH_LOG_FATAL(LOG_APP, "malloc frameData2失败");
                return nullptr;
            }

            memcpy(frameData2.get(), frameData.get(), 11);
            memcpy(frameData2.get() + 11, frameData1.get(), length);

            // 增加header拷贝越界校验
            if (length + 11 < 3 + 8) {
                OH_LOG_FATAL(LOG_APP, "数据长度不足，无法解析header");
                return nullptr;
            }

            UsbDataHeader_2 frame;
            memcpy(&frame, frameData2.get() + 3, 8);

            if (frame.msgid > 20 || frame.len == 0) {
                OH_LOG_FATAL(LOG_APP, "错误数据 %d", frame.order);
                return nullptr; // 智能指针自动释放资源
            }

            // 增加buf拷贝越界校验
            if (frame.len > length) {
                OH_LOG_FATAL(LOG_APP, "frame.len(%d)超过实际数据长度(%d)", frame.len, length);
                return nullptr;
            }

            // 用智能指针管理frame.buf
            std::unique_ptr<unsigned char, decltype(&free)> frameBuf(static_cast<unsigned char *>(malloc(frame.len)),
                                                                     free);
            if (!frameBuf) {
                OH_LOG_FATAL(LOG_APP, "malloc frameBuf失败");
                return nullptr;
            }
            memcpy(frameBuf.get(), frameData2.get() + 3 + 8, frame.len);

            int len = frame.len;

            napi_value args[1];
            size_t argc = 1;
            // 2. 提取 ArkTS 传递的参数（数组）
            napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
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


            *//*   jbyteArray jbyteArray = env->NewByteArray(len);
               env->SetByteArrayRegion(jbyteArray, 0, len, reinterpret_cast<const jbyte *>(frameBuf.get()));*//*
            napi_value array_buffer;
            void *buffer_ptr = nullptr;
            napi_status status1 = napi_create_arraybuffer(env, len, &buffer_ptr, &array_buffer);

            if (status1 != napi_ok || buffer_ptr == nullptr) {
                OH_LOG_ERROR(LOG_APP, "Failed to create ArrayBuffer");
                return nullptr; // 返回null而非无效array_buffer
            }

            // 复制数据到ArrayBuffer
            memcpy(buffer_ptr, frameBuf.get(), len);


            return array_buffer;
        }
    }
    // 所有智能指针在函数退出时自动释放
    return nullptr;
}*/
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_releaseVideoStream(JNIEnv *env, jclass clazz) {
//    FHLoopManager::GetInstance().releaseVideoStream();
//}
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_releaseAudioStream(JNIEnv *env, jclass clazz) {
//    FHLoopManager::GetInstance().releaseAudioStream();
//}
//
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_releaseUsbStream(JNIEnv *env, jclass clazz) {
//    if (my1UsbLoopBufDataHandle != nullptr) {
//        LBUF_Clear(my1UsbLoopBufDataHandle);
//        LBUF_Destory(my1UsbLoopBufDataHandle);
//        my1UsbLoopBufDataHandle = nullptr;
//    }
//}
//
// extern "C"
// JNIEXPORT jboolean JNICALL
// Java_com_vison_sdk_VNDK_initDecode(JNIEnv *env, jclass clazz, jint decodeId) {
//    return initDecode(decodeId);
//}
//
//
// extern "C"
// JNIEXPORT jbyteArray JNICALL
// Java_com_vison_sdk_VNDK_decodeFrameArray(JNIEnv *env, jclass clazz, jbyteArray inFrame, jint length, jintArray info) {
//
//    //LOGE("解码开始");
//    isDecoding = true;
//    char *pInBuffer = reinterpret_cast<char *>(env->GetByteArrayElements(inFrame, JNI_FALSE));
//    char *pOutBuffer = nullptr;
//
//    int width, height;
//    decode(pInBuffer, length, width, height, pOutBuffer);
//
//    // size
//    int size = width * height * 3 / 2;
//
//    env->ReleaseByteArrayElements(inFrame, reinterpret_cast<jbyte *>(pInBuffer), 0);
//
//    if (pOutBuffer == nullptr) {
//        // 解码失败或输出缓冲区为空
//        LOGE("解码失败或输出缓冲区为空");
//        free(pOutBuffer);
//        isDecoding = false;
//        return nullptr;
//    }
//
//
//    // LOGE("pOutBuffer : %s",pOutBuffer);
//    //更新java层数据
//    int *pHeader = env->GetIntArrayElements(info, JNI_FALSE);
//
//    if (pHeader == nullptr) {
//        // 解码失败或输出缓冲区为空
//        LOGE("解码失败,pHeader为空");
//        free(pOutBuffer);
//        isDecoding = false;
//        return nullptr;
//    }
//    // 宽
//    pHeader[0] = width;
//    // 高
//    pHeader[1] = height;
//    pHeader[2] = size;
//    //通知更新
//    env->ReleaseIntArrayElements(info, pHeader, 0);
//
//    jbyteArray byteArray = env->NewByteArray(size);
//    env->SetByteArrayRegion(byteArray, 0, size, reinterpret_cast<const jbyte *>(pOutBuffer));
//
//    free(pOutBuffer);
//    isDecoding = false;
//    //LOGE("解码结束");
//    return byteArray;
//}
//
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_decodeFrameBuffer(JNIEnv *env, jclass clazz, jbyteArray inFrame, jint length, jbyteArray outFrame, jintArray info) {
//
//    // 检查输入参数是否为null
//    if (inFrame == nullptr || outFrame == nullptr || info == nullptr || length <= 0) {
//        LOGE("无效的输入参数");
//        return 0;
//    }
//
//    // 检查info数组长度
//    jsize infoLen = env->GetArrayLength(info);
//    if (infoLen < 3) {
//        LOGE("info数组长度不足，需要至少3个元素");
//        return 0;
//    }
//
//    isDecoding = true;
//    jint result = 0;
//    jbyte *pInBuffer = nullptr;
//    jbyte *pOutBuffer = nullptr;
//    jint *pHeader = nullptr;
//
//    // LOGE("解码开始");
//    try {
//        // 获取输入缓冲区
//        pInBuffer = env->GetByteArrayElements(inFrame, JNI_FALSE);
//        if (pInBuffer == nullptr) {
//            LOGE("无法获取输入缓冲区");
//            throw std::exception();
//        }
//
//        // 获取输出缓冲区
//        pOutBuffer = env->GetByteArrayElements(outFrame, JNI_FALSE);
//        if (pOutBuffer == nullptr) {
//            LOGE("无法获取输出缓冲区");
//            throw std::exception();
//        }
//
//        char *inData = reinterpret_cast<char *>(pInBuffer);
//        char *outData = reinterpret_cast<char *>(pOutBuffer);
//
//        // 执行解码操作
//        int width, height;
//        result = decode(inData, length, width, height, outData);
//        if (result != 1) {
//            LOGE("解码失败，返回值: %d", result);
//            throw std::exception();
//        }
//
//        // 计算输出数据大小
//        int size = width * height * 3 / 2;
//
//        // 检查输出缓冲区是否足够大
//        jsize outFrameLen = env->GetArrayLength(outFrame);
//        if (outFrameLen < size) {
//            LOGE("输出缓冲区太小，需要: %d, 实际: %d", size, outFrameLen);
//            throw std::exception();
//        }
//
//        // 更新Java层信息
//        pHeader = env->GetIntArrayElements(info, JNI_FALSE);
//        if (pHeader == nullptr) {
//            LOGE("无法获取info数组元素");
//            throw std::exception();
//        }
//
//        pHeader[0] = width;   // 宽度
//        pHeader[1] = height;  // 高度
//        pHeader[2] = size;    // 实际数据大小
//
//    } catch (...) {
//        result = 0;
//        LOGE("decodeFrameBuffer 解码异常");
//    }
//
//    // 增加nullptr判断
//    env->ReleaseIntArrayElements(info, pHeader, result == 1 ? 0 : JNI_ABORT);
//    env->ReleaseByteArrayElements(outFrame, pOutBuffer, result == 1 ? 0 : JNI_ABORT);
//    env->ReleaseByteArrayElements(inFrame, pInBuffer, JNI_ABORT);
//
//    isDecoding = false;
//    // LOGE("解码结束");
//    return result;
//}
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_releaseDecode(JNIEnv *env, jclass clazz) {
//    if (isDecoding) {
//        // 以防在解码过程中销毁导致奔溃
//        usleep(10 * 1000); // 10毫秒
//        Java_com_vison_sdk_VNDK_releaseDecode(env, clazz);
//    } else {
//        release();
//    }
//}
//
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_setShowLog(JNIEnv *env, jclass clazz, jboolean show) {
//    setShowLog(show);
//}
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_convertNV12ToI420(JNIEnv *env, jclass clazz, jbyteArray nv12, jbyteArray i420, jint width, jint height) {
//    jbyte *nv12_yuv = env->GetByteArrayElements(nv12, JNI_FALSE);
//    jbyte *i420_yuv = env->GetByteArrayElements(i420, JNI_FALSE);
//
//    uint8_t *y = (uint8_t *) i420_yuv;
//    uint8_t *u = (uint8_t *) i420_yuv + width * height;
//    uint8_t *v = (uint8_t *) i420_yuv + width * height * 5 / 4;
//
//    libyuv::NV12ToI420((const uint8_t *) nv12_yuv,
//                       width,
//                       (const uint8_t *) (nv12_yuv + width * height),
//                       width,
//                       y,
//                       width,
//                       u,
//                       width / 2,
//                       v,
//                       width / 2,
//                       width,
//                       height);
//
//    env->ReleaseByteArrayElements(nv12, nv12_yuv, 0);
//    env->ReleaseByteArrayElements(i420, i420_yuv, 0);
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_getJPEGPixels(JNIEnv *env, jclass clazz, jbyteArray jpeg, jint length, jintArray size) {
//
//    jbyte *pJpeg = env->GetByteArrayElements(jpeg, JNI_FALSE);
//    int *pSize = env->GetIntArrayElements(size, JNI_FALSE);
//
//    int width = 0, height = 0;
//    int ret = libyuv::MJPGSize((const uint8_t *) pJpeg, length, &width, &height);
//    pSize[0] = width;
//    pSize[1] = height;
//
//    env->ReleaseByteArrayElements(jpeg, pJpeg, 0);
//    env->ReleaseIntArrayElements(size, pSize, 0);
//
//    return ret;
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_convertJPEGToI420(JNIEnv *env, jclass clazz, jbyteArray jpeg, jint length, jbyteArray i420, jint width, jint height) {
//
//    jbyte *pJpeg = env->GetByteArrayElements(jpeg, JNI_FALSE);
//    jbyte *pI420 = env->GetByteArrayElements(i420, JNI_FALSE);
//
//
//    uint8_t *y = (uint8_t *) pI420;
//    uint8_t *u = (uint8_t *) pI420 + width * height;
//    uint8_t *v = (uint8_t *) pI420 + width * height * 5 / 4;
//
//    int ret = libyuv::MJPGToI420((const uint8_t *) pJpeg, length,
//                                 y,
//                                 width,
//                                 u,
//                                 width / 2,
//                                 v,
//                                 width / 2,
//                                 width,
//                                 height,
//                                 width,
//                                 height);
//
//    env->ReleaseByteArrayElements(jpeg, pJpeg, 0);
//    env->ReleaseByteArrayElements(i420, pI420, 0);
//
//    return ret;
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_startRecordVideo(JNIEnv *env, jclass clazz, jboolean is_audio, jint streamType, jstring path, jint width, jint height) {
//    return RecordVideoManager::GetInstance().start(env,is_audio,streamType,path,width,height);
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_commitVideoStream(JNIEnv *env, jclass clazz, jbyteArray data, jint length, jboolean isIFrame, jint frameRate) {
//    return RecordVideoManager::GetInstance().commitVideo(env,data,length,isIFrame,frameRate);
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_commitAudioStream(JNIEnv *env, jclass clazz, jbyteArray data, jint length) {
//    return RecordVideoManager::GetInstance().commitAudio(env,data,length);
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_stopRecordVideo(JNIEnv *env, jclass clazz) {
//    return RecordVideoManager::GetInstance().stop();
//}
//
// extern "C"
// JNIEXPORT jint JNICALL
// Java_com_vison_sdk_VNDK_testData(JNIEnv *env, jclass clazz, jstring output_mp4_path, jstring input_h264_path, jstring input_aac_path) {
//    const char *char_mp4_path = env->GetStringUTFChars(output_mp4_path, JNI_FALSE);
//    const char *char_h264_path = env->GetStringUTFChars(input_h264_path, JNI_FALSE);
//    const char *char_aac_path = env->GetStringUTFChars(input_aac_path, JNI_FALSE);
//    int result = startRecording(char_mp4_path, char_h264_path, char_aac_path);
//
//    env->ReleaseStringUTFChars(output_mp4_path, char_mp4_path);
//    env->ReleaseStringUTFChars(input_h264_path, char_h264_path);
//    env->ReleaseStringUTFChars(input_aac_path, char_aac_path);
//    return result;
//}
//
//
// extern "C"
// JNIEXPORT jboolean JNICALL
// Java_com_vison_sdk_VNDK_srtInit(JNIEnv *env, jclass clazz, jint port, jobject callback) {
//    bool isInit = SrtReceiverManager::GetInstance().Init(env, port, callback) ? JNI_TRUE : JNI_FALSE;
//    return isInit;
//}
//
//
// extern "C"
// JNIEXPORT jboolean JNICALL
// Java_com_vison_sdk_VNDK_srtStart(JNIEnv *env, jclass clazz) {
//    bool isStart = SrtReceiverManager::GetInstance().Start() ? JNI_TRUE : JNI_FALSE;
//    return isStart;
//}
//
// extern "C"
// JNIEXPORT void JNICALL
// Java_com_vison_sdk_VNDK_srtStop(JNIEnv *env, jclass clazz) {
//    SrtReceiverManager::GetInstance().Stop();
//}
//
// extern "C"
// JNIEXPORT jobject JNICALL
// Java_com_vison_sdk_VNDK_srtGetStats(JNIEnv *env, jclass clazz) {
//
//    auto stats = SrtReceiverManager::GetInstance().GetStats();
//
//    jclass statsClass = env->FindClass("com/vison/sdk/SrtStats");
//    if (!statsClass) {
//        return nullptr;
//    }
//
//    jmethodID constructor = env->GetMethodID(statsClass, "<init>", "()V");
//    if (!constructor) {
//        env->DeleteLocalRef(statsClass);
//        return nullptr;
//    }
//
//    jobject statsObj = env->NewObject(statsClass, constructor);
//    if (!statsObj) {
//        env->DeleteLocalRef(statsClass);
//        return nullptr;
//    }
//
//    jfieldID reconnectField = env->GetFieldID(statsClass, "reconnectCount", "J");
//    jfieldID packetsField = env->GetFieldID(statsClass, "packetsReceived", "J");
//    jfieldID bytesField = env->GetFieldID(statsClass, "bytesReceived", "J");
//
//    if (reconnectField && packetsField && bytesField) {
//        env->SetLongField(statsObj, reconnectField, static_cast<jlong>(stats.reconnectCount));
//        env->SetLongField(statsObj, packetsField, static_cast<jlong>(stats.packetsReceived));
//        env->SetLongField(statsObj, bytesField, static_cast<jlong>(stats.bytesReceived));
//    }
//
//    env->DeleteLocalRef(statsClass);
//    return statsObj;
//}

/*
extern "C"
JNIEXPORT void JNICALL
Java_com_vison_sdk_VNDK_srtRelease(JNIEnv *env, jclass clazz) {
    SrtReceiverManager::GetInstance().Release(env);
}


extern "C"
JNIEXPORT void JNICALL
Java_com_vison_sdk_VNDK_createLoopUsbStream(JNIEnv *env, jclass clazz) {
    UsbLoopManager::GetInstance().createLoopUsbStream();
}


extern "C"
JNIEXPORT void JNICALL
Java_com_vison_sdk_VNDK_addLoopUsbStream(JNIEnv *env, jclass clazz, jbyteArray data, jint data_length) {
    UsbLoopManager::GetInstance().addLoopUsbStream(env,data,data_length);
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_vison_sdk_VNDK_getLoopUsbOneFrame(JNIEnv *env, jclass clazz, jbyteArray buffer,jintArray header) {
    return UsbLoopManager::GetInstance().getLoopUsbOneFrame(env,buffer,header);
}

extern "C"
JNIEXPORT void JNICALL
Java_com_vison_sdk_VNDK_releaseLoopUsbStream(JNIEnv *env, jclass clazz) {
    UsbLoopManager::GetInstance().releaseLoopUsbStream();
}*/
