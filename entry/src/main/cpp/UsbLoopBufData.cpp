//
// Created by Vison on 2023/12/16.
//

#include "UsbLoopBufData.h"
#include "LoopBuf.h"
#include "LogUtils.h"
#include "UsbDataHeader.h"
#include <cstdlib>
#include <cstring>
#include "LogUtils.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag
#define LOGD(fmt, ...) OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGI(fmt, ...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGE(fmt, ...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)

typedef struct {
    USBHANDLE usbHandle;
    unsigned char order;
} USBDATA_t;


static unsigned char _USBDATA_IsFrameHead(unsigned char flag1, unsigned char flag2, unsigned char flag3) {
    if (flag1 == 0xff && flag2 == 0x56 && flag3 == 0x53)
        return 1;
    return 0;
}

static unsigned char _USBDATA_FindFrameHead(char *pBuf1, int iLen1, char *pBuf2, int iLen2, int *pPos) {
    char *pBuf = NULL;
    int iPos2 = 0;

    (*pPos) = 0;
    while ((*pPos) <= iLen1 - 3) {
        pBuf = (char *) (pBuf1 + (*pPos));
        if (_USBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2]))
            return 1;

        (*pPos)++;
    }

    if (0 == pBuf2 || iLen2 < 11)
        return 0;

    if (iLen1 >= 2) {
        pBuf = pBuf1 + (*pPos);
        if (_USBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf2[0]))
            return 1;
        (*pPos)++;
    }

    if (iLen1 >= 1) {
        pBuf = pBuf1 + (*pPos);
        if (_USBDATA_IsFrameHead(pBuf[0], pBuf2[0], pBuf2[1]))
            return 1;
    }

    (*pPos) = iLen1;

    iPos2 = 0;
    while (iPos2 <= iLen2 - 3) {
        pBuf = (char *) (pBuf2 + iPos2);
        if (_USBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2])) {
            (*pPos) += iPos2;
            return 1;
        }

        iPos2++;
    }

    (*pPos) += iPos2;
    return 0;
}


unsigned char _USBDATA_GetOneFrame(USBHANDLE handle, char *pHead, char *pFrame) {
    unsigned int pos = 0;
    unsigned int preReadLen = 0;
    unsigned int usedSize = 0;
    char *pReadPtr1 = NULL;
    int iReadLen1 = 0;
    char *pReadPtr2 = NULL;
    int iReadLen2 = 0;
    UsbDataHeader stUsbDataHeader;
    unsigned int headLen = sizeof(UsbDataHeader);
    UsbDataHeader *pFrameHead = (UsbDataHeader *) pHead;
    USBDATA_t *pHandle = (USBDATA_t *) handle;

    if (!pHandle)
        return 0;

    if (LBUF_GetUsedSize(pHandle->usbHandle) < headLen)
        return 0;

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->usbHandle);

    LBUF_AdvGetReadPtr(pHandle->usbHandle, &pReadPtr1, (unsigned int *) &iReadLen1, &pReadPtr2, (unsigned int *) &iReadLen2);

    if (!_USBDATA_FindFrameHead(pReadPtr1, iReadLen1, pReadPtr2, iReadLen2, (int *) &pos)) {
        LBUF_SetReadPos(pHandle->usbHandle, pos, 0);
        LBUF_Unlock(pHandle->usbHandle);
        //LOGE("USB _USBDATA_FindFrameHead error");
        return 0;
    }

    LBUF_SetReadPos(pHandle->usbHandle, pos, 0);

    LBUF_Unlock(pHandle->usbHandle);

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->usbHandle);

    usedSize = LBUF_GetUsedSize(pHandle->usbHandle);
    if (usedSize < headLen) {
        LBUF_Unlock(pHandle->usbHandle);
        return 0;
    }

    preReadLen = headLen;
    if (!LBUF_PreRead(pHandle->usbHandle, (char *) &stUsbDataHeader, &preReadLen, 0, 0)
        || preReadLen < headLen) {
        LBUF_Unlock(pHandle->usbHandle);
        return 0;
    }

    if (headLen + stUsbDataHeader.len > usedSize) {
        LBUF_Unlock(pHandle->usbHandle);
        return 0;
    }

    memcpy(pFrameHead, &stUsbDataHeader, sizeof(stUsbDataHeader));
    pHandle->order = pFrameHead->order;
    LBUF_SetReadPos(pHandle->usbHandle, headLen, 0);


    preReadLen = pFrameHead->len;
    LBUF_PreRead(pHandle->usbHandle, pFrame, &preReadLen, 0, 0);
    LBUF_SetReadPos(pHandle->usbHandle, preReadLen, 0);

    LBUF_Unlock(pHandle->usbHandle);

    return 1;
}


USBHANDLE USBDATA_Create(unsigned int memSize) {
    USBDATA_t *pHandle = (USBDATA_t *) malloc(sizeof(USBDATA_t));
    if (!pHandle)
        return 0;

    memset(pHandle, 0, sizeof(USBDATA_t));

    pHandle->usbHandle = LBUF_Create(memSize);
    if (!pHandle->usbHandle) {
        free(pHandle);
        return 0;
    }
    LOGI("USB LOOP CREATE SUCCESS");
    return (USBHANDLE) pHandle;
}

unsigned char USBDATA_Destroy(USBHANDLE handle) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    LBUF_Destory(pHandle->usbHandle);
    free(pHandle);
    return 1;
}

unsigned char USBDATA_Clear(USBHANDLE handle) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    LBUF_Clear(pHandle->usbHandle);
    return 1;
}

unsigned char USBDATA_Write(USBHANDLE handle, char *pSrcBuf, unsigned int dwWriteLen) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    return LBUF_Write(pHandle->usbHandle, pSrcBuf, dwWriteLen);
}

unsigned char USBDATA_GetOneFrame(USBHANDLE handle, char *pHead, char *pFrame) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    return _USBDATA_GetOneFrame(handle, pHead, pFrame);
}

unsigned char USBDATA_AdvGetWritePtr(USBHANDLE handle, char **ppWritePtr1, unsigned int *pWriteLen1, char **ppWritePtr2, unsigned int *pWriteLen2) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    return LBUF_AdvGetWritePtr(pHandle->usbHandle, ppWritePtr1, pWriteLen1, ppWritePtr2, pWriteLen2);
}

unsigned char USBDATA_AdvSetWritePos(USBHANDLE handle, unsigned int dwWriteLen) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    return LBUF_AdvSetWritePos(pHandle->usbHandle, dwWriteLen);
}

unsigned char USBDATA_Lock(USBHANDLE handle) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    return LBUF_Lock(pHandle->usbHandle);
}

unsigned char USBDATA_Unlock(USBHANDLE handle) {
    USBDATA_t *pHandle = (USBDATA_t *) handle;
    if (!pHandle)
        return 0;
    return LBUF_Unlock(pHandle->usbHandle);
}




