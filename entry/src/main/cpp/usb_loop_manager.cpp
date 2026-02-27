//
// Created by Vison on 2025/9/17.
//

#include "usb_loop_manager.h"


UsbLoopManager &UsbLoopManager::GetInstance() {
    static  UsbLoopManager instance;
    return instance;
}

void UsbLoopManager::createLoopUsbStream() {
    // 释放之前的创建
    releaseLoopUsbStream();

    // 创建新的缓冲区
    myUsbLoopBufDataHandle = USBDATA_Create(1024 * 1024 * 10); // 10MB
    pUsbFrame = std::make_unique<char[]>(0x100000); // 1MB
}

/*void UsbLoopManager::addLoopUsbStream(JNIEnv *env, jbyteArray data, jint data_length) {
    // 1. 基础校验：句柄空/数据空/长度无效直接返回（上层已保证长度正确，仍做基础防护）
    if (myUsbLoopBufDataHandle == nullptr || data == nullptr || data_length <= 0) {
        return;
    }

    // 2. 分配C层缓冲区（关键：用智能指针自动释放，避免泄漏）
    std::unique_ptr<char[]> byteData(new char[data_length]);
    // 从Java数组拷贝数据到C层缓冲区（上层已保证data_length正确，无需额外校验长度）
    env->GetByteArrayRegion(data, 0, data_length, reinterpret_cast<jbyte *>(byteData.get()));

    // 3. 循环缓冲区操作：加锁→写数据→解锁（核心逻辑保留）
    int iRecvLen = data_length;
    char *pLoopBuf1 = nullptr;
    int iLoopBufLen1 = 0;
    char *pLoopBuf2 = nullptr;
    int iLoopBufLen2 = 0;

    USBDATA_Lock(myUsbLoopBufDataHandle);   // 加锁（确保线程安全）
    // 尝试获取写入指针
    if (USBDATA_AdvGetWritePtr(myUsbLoopBufDataHandle, &pLoopBuf1,
                               (unsigned int *) &iLoopBufLen1, &pLoopBuf2,
                               (unsigned int *) &iLoopBufLen2)) {
        // 分两种情况拷贝数据（与原逻辑完全一致）
        if (iLoopBufLen1 >= data_length) {
            memcpy(pLoopBuf1, byteData.get(), iRecvLen);
        } else {
            memcpy(pLoopBuf1, byteData.get(), iLoopBufLen1);
            memcpy(pLoopBuf2, byteData.get() + iLoopBufLen1, iRecvLen - iLoopBufLen1);
        }
        // 更新写入位置
        USBDATA_AdvSetWritePos(myUsbLoopBufDataHandle, iRecvLen);
    }
    USBDATA_Unlock(myUsbLoopBufDataHandle);
}*/

/*jint UsbLoopManager::getLoopUsbOneFrame(JNIEnv *env, jbyteArray buffer, jintArray header) {
    if (myUsbLoopBufDataHandle == nullptr) {
        LOGE("myUsbLoopBufDataHandle is null");
        return -1;
    }

    UsbDataHeader stHead;
    if (!USBDATA_GetOneFrame(myUsbLoopBufDataHandle, (char *) &stHead, pUsbFrame.get())) {
        return -2;
    }


    //更新java层数据
    int *pHeader =env->GetIntArrayElements(header,0);
    pHeader[0]=stHead.order;
    pHeader[1]=stHead.len;
    pHeader[2]=stHead.msgid;

    //LOGE("UsbOneFrame  %d  %d  %d %d", stHead.order, stHead.msgid, stHead.check, len);
    //通知更新
    env->ReleaseIntArrayElements(header,pHeader,0);


    int frameLen = stHead.len;
    jbyte *bufferPtr = env->GetByteArrayElements(buffer, nullptr);
    if (bufferPtr == nullptr) {
        return -3; // 内存获取失败
    }
    //  复制帧数据到buffer（覆盖旧数据）
    memcpy(bufferPtr, pUsbFrame.get(), frameLen);
    env->ReleaseByteArrayElements(buffer, bufferPtr, 0);
    return frameLen;
}*/

void UsbLoopManager::releaseLoopUsbStream() {

    if (myUsbLoopBufDataHandle != nullptr) {
        USBDATA_Clear(myUsbLoopBufDataHandle);
        USBDATA_Destroy(myUsbLoopBufDataHandle);
        myUsbLoopBufDataHandle = nullptr;
    }

    if (pUsbFrame != nullptr) {
        pUsbFrame.reset();
    }
}
