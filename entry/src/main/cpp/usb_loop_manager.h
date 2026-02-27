//
// Created by Vison on 2025/9/17.
//

#ifndef VISONNDK_USB_LOOP_MANAGER_H
#define VISONNDK_USB_LOOP_MANAGER_H


#include <memory>
#include <mutex>
#include "LoopBuf.h"
#include "UsbLoopBufData.h"
#include "UsbDataHeader.h"
#include "LogUtils.h"

class UsbLoopManager {
public:
    // 单例实例
    static UsbLoopManager &GetInstance();

    // 禁止拷贝和赋值
    UsbLoopManager(const UsbLoopManager &) = delete;

    UsbLoopManager &operator=(const UsbLoopManager &) = delete;

    // 创建USB循环流
    void createLoopUsbStream();

  /*  // 添加数据到USB循环流
    void addLoopUsbStream(JNIEnv *env, jbyteArray data, jint data_length);

    // 从USB循环流获取一帧数据
    jint getLoopUsbOneFrame(JNIEnv *env, jbyteArray buffer, jintArray header);*/

    // 释放USB循环流资源
    void releaseLoopUsbStream();

private:

    // 私有构造函数：仅单例可创建
    UsbLoopManager() : myUsbLoopBufDataHandle(nullptr) {};

    // 私有析构函数：自动释放资源
    ~UsbLoopManager() {
        releaseLoopUsbStream();
    }

    // 成员变量
    LBUFHANDLE myUsbLoopBufDataHandle;  // USB循环缓冲区句柄
    std::unique_ptr<char[]> pUsbFrame;  // 帧数据缓冲区
};


#endif //VISONNDK_USB_LOOP_MANAGER_H
