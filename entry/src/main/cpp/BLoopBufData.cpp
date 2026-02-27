#include "BLoopBufData.h"
#include "NetProtocol8610.h"
#include "NetProtocol8810.h"
#include "NetProtocol8620.h"
#include "NetProtocol.h"
#include "LoopBuf.h"
#include "LogUtils.h"

#if defined(_MSC_VER)
#include <windows.h>
#define U64 unsigned __int64
#else
#include <stdlib.h>
#include <string.h>
#define U64 unsigned long long
#endif
#include <hilog/log.h>
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag

#define FFMPEG_FRAME_DATALEN_ALIGN 1

typedef struct {
    LBUFHANDLE dwLBUFHandle;
    unsigned char bBufIsOver;
    unsigned int dwBufIsOver;

    unsigned char frame_num;
    U64 timestamp;

    unsigned int dwBufType;
} BLBDATA_t;

static unsigned char _BLBDATA_IsFrameHead(unsigned char flag1, unsigned char flag2, unsigned char flag3,
                                          unsigned char flag4) {
    if (flag1 == 0x00 && flag2 == 0x00 && flag3 == 0x01 &&
        (flag4 == 0xa0 || flag4 == 0xa1 || flag4 == 0xa2 || flag4 == 0xa4 || flag4 == 0xa5))
        return 1;
    return 0;
}

static unsigned char _BLBDATA_61_FindFrameHead(char *pBuf1, int iLen1, char *pBuf2, int iLen2, int *pPos) {
    char *pBuf = NULL;
    int iPos2 = 0;

    (*pPos) = 0;
    while ((*pPos) <= iLen1 - 4) {
        pBuf = (char *)(pBuf1 + (*pPos));
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf[3]))
            return 1;

        (*pPos)++;
    }

    if (0 == pBuf2 || iLen2 < 40)
        return 0;

    if (iLen1 >= 3) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf2[0]))
            return 1;
        (*pPos)++;
    }

    if (iLen1 >= 2) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf2[0], pBuf2[1]))
            return 1;
        (*pPos)++;
    }

    if (iLen1 >= 1) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf2[0], pBuf2[1], pBuf2[2]))
            return 1;
    }

    (*pPos) = iLen1;

    iPos2 = 0;
    while (iPos2 <= iLen2 - 4) {
        pBuf = (char *)(pBuf2 + iPos2);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf[3])) {
            (*pPos) += iPos2;
            return 1;
        }

        iPos2++;
    }

    (*pPos) += iPos2;
    return 0;
}

unsigned char _BLBDATA_61_GetOneFrame(BLHANDLE dwHandle, char *pHead, char *pFrame, unsigned char bIsIFrame) {
    unsigned int pos = 0;
    unsigned int posTemp = 0;
    unsigned int framePosTemp = 0;
    unsigned int preReadLen = 0;
    unsigned int usedSize = 0;
    unsigned char head_flag[4];
    unsigned int frame_num = 0;
    unsigned int block_num = 0;
    char *pReadPtr1 = NULL;
    int iReadLen1 = 0;
    char *pReadPtr2 = NULL;
    int iReadLen2 = 0;
    FHNP_61_BlockHead_t stBlockHead;
    FHNP_61_FrameInfo_t stFrameInfo;
    static unsigned int BHLEN = sizeof(FHNP_61_BlockHead_t);
    static unsigned int FILEN = sizeof(FHNP_61_FrameInfo_t);
    FHNP_Dev_FrameHead_t *pFrameHead = (FHNP_Dev_FrameHead_t *)pHead;
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;

    if (LBUF_GetUsedSize(pHandle->dwLBUFHandle) < BHLEN + FILEN)
        return 0;

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    LBUF_AdvGetReadPtr(pHandle->dwLBUFHandle, &pReadPtr1, (unsigned int *)&iReadLen1, &pReadPtr2,
                       (unsigned int *)&iReadLen2);

    if (!_BLBDATA_61_FindFrameHead(pReadPtr1, iReadLen1, pReadPtr2, iReadLen2, (int *)&pos)) {
        LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);

    LBUF_Unlock(pHandle->dwLBUFHandle);

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    usedSize = LBUF_GetUsedSize(pHandle->dwLBUFHandle);
    if (usedSize <= BHLEN + BHLEN) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    preReadLen = BHLEN;
    if (!LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stBlockHead, &preReadLen, 0, 0) || preReadLen < BHLEN) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    if (0 != stBlockHead.block_num) {
        pos = BHLEN + stBlockHead.block_len;
        if (stBlockHead.block_flag & 0x02) {
            pos = BHLEN;
        }

        LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);

        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    } else {
        pos = 0;
        memcpy(head_flag, stBlockHead.flag, 4);
        frame_num = stBlockHead.frame_num;
        block_num = stBlockHead.block_num;
        while (!(stBlockHead.block_flag & 0x02)) {
            pos += BHLEN + stBlockHead.block_len;
            preReadLen = BHLEN;
            if (pos + BHLEN >= usedSize ||
                !LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stBlockHead, &preReadLen, pos, 0) || preReadLen < BHLEN) {
                LBUF_Unlock(pHandle->dwLBUFHandle);
                return 0;
            }

            if (head_flag[0] != stBlockHead.flag[0] || head_flag[1] != stBlockHead.flag[1] ||
                head_flag[2] != stBlockHead.flag[2] || head_flag[3] != stBlockHead.flag[3] ||
                stBlockHead.frame_num != frame_num || stBlockHead.block_num != (block_num + 1)) {
                LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);
                LBUF_Unlock(pHandle->dwLBUFHandle);
                return 0;
            }

            block_num++;
        }

        if (pos + BHLEN + FILEN + (int)stBlockHead.block_len > usedSize) {
            LBUF_Unlock(pHandle->dwLBUFHandle);
            return 0;
        }

        preReadLen = FILEN;
        LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stFrameInfo, &preReadLen, pos + BHLEN, 0);

        memset(pFrameHead, 0, sizeof(FHNP_Dev_FrameHead_t));
        memcpy(pFrameHead->FrmHd, stBlockHead.flag, 4);
        pFrameHead->Vmsflag = stBlockHead.encid;
        pFrameHead->AVOption = stFrameInfo.avopt;
        pFrameHead->VideoFormat = stFrameInfo.vformat;
        pFrameHead->AudioFormat = stFrameInfo.aformat;
        pFrameHead->restart_flag = stFrameInfo.restart;
        pFrameHead->frmnum = stBlockHead.frame_num;
        pFrameHead->Framerate = stFrameInfo.frame_rate;
        pFrameHead->Bitrate = stFrameInfo.bitrate;
        pFrameHead->framelen = stFrameInfo.frame_len;
        pFrameHead->HideAlarmStatus = (stFrameInfo.alarm_info & 0x10);
        pFrameHead->alarmstatus = stFrameInfo.width << 16 | stFrameInfo.height;
        pFrameHead->mdstatus = (stFrameInfo.alarm_info & 0x01);
        pFrameHead->timestamp = stFrameInfo.timestamp;
        pFrameHead->reserve[0] = stFrameInfo.audio_info;
        pFrameHead->reserve[3] = stBlockHead.frame_num;

        if (0xa0 == pFrameHead->FrmHd[3] || 0xa1 == pFrameHead->FrmHd[3] || 0xa2 == pFrameHead->FrmHd[3]) {
            if (0 == pHandle->timestamp) {
                pHandle->timestamp = stFrameInfo.timestamp;
                pHandle->frame_num = stBlockHead.frame_num;
            } else {
                pHandle->timestamp = stFrameInfo.timestamp;
                pHandle->frame_num = stBlockHead.frame_num;
            }
        }

        if (pFrameHead->framelen > 262144 || stFrameInfo.frame_rate > 30) {
            LBUF_SetReadPos(pHandle->dwLBUFHandle, pos + BHLEN, 0);
            LBUF_Unlock(pHandle->dwLBUFHandle);
            return 0;
        }

        posTemp = 0;
        while (1) {
            preReadLen = BHLEN;
            LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stBlockHead, &preReadLen, posTemp, 0);

            preReadLen = stBlockHead.block_len;
            if (posTemp == pos) {
                LBUF_PreRead(pHandle->dwLBUFHandle, pFrame + framePosTemp, &preReadLen, posTemp + BHLEN + FILEN, 0);
                break;
            } else {
                LBUF_PreRead(pHandle->dwLBUFHandle, pFrame + framePosTemp, &preReadLen, posTemp + BHLEN, 0);
            }

            posTemp += BHLEN + stBlockHead.block_len;
            framePosTemp += preReadLen;
        }

        LBUF_SetReadPos(pHandle->dwLBUFHandle, pos + BHLEN + FILEN + stBlockHead.block_len, 0);
    }

    LBUF_Unlock(pHandle->dwLBUFHandle);

    return 1;
}


static unsigned char _BLBDATA_81_FindFrameHead(char *pBuf1, int iLen1, char *pBuf2, int iLen2, int *pPos) {
    char *pBuf = NULL;
    int iPos2 = 0;

    (*pPos) = 0;
    while ((*pPos) <= iLen1 - 4) {
        pBuf = (char *)(pBuf1 + (*pPos));
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf[3])) {
            return 1;
        }

        (*pPos)++;
    }

    if (0 == pBuf2 || iLen2 < sizeof(FHNP_81_FrameHead_t))
        return 0;

    if (iLen1 >= 3) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf2[0])) {
            return 1;
        }
        (*pPos)++;
    }

    if (iLen1 >= 2) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf2[0], pBuf2[1])) {
            return 1;
        }
        (*pPos)++;
    }

    if (iLen1 >= 1) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf2[0], pBuf2[1], pBuf2[2])) {
            return 1;
        }
    }

    (*pPos) = iLen1;

    iPos2 = 0;
    while (iPos2 <= iLen2 - 4) {
        pBuf = (char *)(pBuf2 + iPos2);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf[3])) {
            (*pPos) += iPos2;
            return 1;
        }

        iPos2++;
    }

    (*pPos) += iPos2;
    return 0;
}

unsigned char _BLBDATA_81_GetOneFrame(BLHANDLE dwHandle, char *pHead, char *pFrame, unsigned char bIsIFrame) {
    unsigned int pos = 0;
    unsigned int preReadLen = 0;
    unsigned int usedSize = 0;
    char *pReadPtr1 = NULL;
    int iReadLen1 = 0;
    char *pReadPtr2 = NULL;
    int iReadLen2 = 0;
    FHNP_81_FrameHead_t stFrameHead_81;
    unsigned int headLen = sizeof(FHNP_81_FrameHead_t);
    FHNP_Dev_FrameHead_t *pFrameHead = (FHNP_Dev_FrameHead_t *)pHead;
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;

    if (!pHandle)
        return 0;

    if (LBUF_GetUsedSize(pHandle->dwLBUFHandle) < headLen)
        return 0;

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    LBUF_AdvGetReadPtr(pHandle->dwLBUFHandle, &pReadPtr1, (unsigned int *)&iReadLen1, &pReadPtr2,
                       (unsigned int *)&iReadLen2);

    if (!_BLBDATA_81_FindFrameHead(pReadPtr1, iReadLen1, pReadPtr2, iReadLen2, (int *)&pos)) {
        LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);

    LBUF_Unlock(pHandle->dwLBUFHandle);

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    usedSize = LBUF_GetUsedSize(pHandle->dwLBUFHandle);
    if (usedSize < headLen) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    preReadLen = headLen;
    if (!LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stFrameHead_81, &preReadLen, 0, 0) || preReadLen < headLen) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    {
        if (headLen + stFrameHead_81.framelen > usedSize) {
            LBUF_Unlock(pHandle->dwLBUFHandle);
            return 0;
        }

        memcpy(pFrameHead, &stFrameHead_81, sizeof(stFrameHead_81));
        pFrameHead->reserve[3] = stFrameHead_81.frmnum;

        if (0xa0 == pFrameHead->FrmHd[3] || 0xa1 == pFrameHead->FrmHd[3] || 0xa2 == pFrameHead->FrmHd[3]) {
            if (0 == pHandle->timestamp) {
                pHandle->timestamp = pFrameHead->timestamp;
                pHandle->frame_num = pFrameHead->frmnum;
            } else {
                pHandle->timestamp = pFrameHead->timestamp;
                pHandle->frame_num = pFrameHead->frmnum;
            }
        }

        {
            LBUF_SetReadPos(pHandle->dwLBUFHandle, headLen, 0);

            preReadLen = pFrameHead->framelen;
            LBUF_PreRead(pHandle->dwLBUFHandle, pFrame, &preReadLen, 0, 0);
            LBUF_SetReadPos(pHandle->dwLBUFHandle, preReadLen, 0);
        }
    }

    LBUF_Unlock(pHandle->dwLBUFHandle);

    return 1;
}


static unsigned char _BLBDATA_62_FindFrameHead(char *pBuf1, int iLen1, char *pBuf2, int iLen2, int *pPos) {
    char *pBuf = NULL;
    int iPos2 = 0;

    (*pPos) = 0;
    while ((*pPos) <= iLen1 - 4) {
        pBuf = (char *)(pBuf1 + (*pPos));
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf[3])) {
            return 1;
        }

        (*pPos)++;
    }

    if (0 == pBuf2 || iLen2 < sizeof(FHNP_62_FrameHead_t))
        return 0;

    if (iLen1 >= 3) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf2[0])) {
            return 1;
        }
        (*pPos)++;
    }

    if (iLen1 >= 2) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf2[0], pBuf2[1])) {
            return 1;
        }
        (*pPos)++;
    }

    if (iLen1 >= 1) {
        pBuf = pBuf1 + (*pPos);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf2[0], pBuf2[1], pBuf2[2])) {
            return 1;
        }
    }

    (*pPos) = iLen1;

    iPos2 = 0;
    while (iPos2 <= iLen2 - 4) {
        pBuf = (char *)(pBuf2 + iPos2);
        if (_BLBDATA_IsFrameHead(pBuf[0], pBuf[1], pBuf[2], pBuf[3])) {
            (*pPos) += iPos2;
            return 1;
        }

        iPos2++;
    }

    (*pPos) += iPos2;
    return 0;
}

unsigned char _BLBDATA_62_GetOneFrame(BLHANDLE dwHandle, char *pHead, char *pFrame, unsigned char bIsIFrame) {
    
    unsigned int pos = 0;
    unsigned int preReadLen = 0;
    unsigned int usedSize = 0;
    char *pReadPtr1 = NULL;
    int iReadLen1 = 0;
    char *pReadPtr2 = NULL;
    int iReadLen2 = 0;
    FHNP_62_FrameHead_t stFrameHead_62;
    unsigned int headLen = sizeof(FHNP_62_FrameHead_t);
    FHNP_Dev_FrameHead_t *pFrameHead = (FHNP_Dev_FrameHead_t *)pHead;
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle){
        //OH_LOG_FATAL(LOG_APP, "帧数据 循环buff为0");
        return 0;
    }
    
  /*  int i = LBUF_GetUsedSize(pHandle->dwLBUFHandle);
    OH_LOG_FATAL(LOG_APP, "_帧数据 GetUsedSize ==%{public}d", i);*/
    if (LBUF_GetUsedSize(pHandle->dwLBUFHandle) < headLen){
         return 0;
    }
    
    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    LBUF_AdvGetReadPtr(pHandle->dwLBUFHandle, &pReadPtr1, (unsigned int *)&iReadLen1, &pReadPtr2,
                       (unsigned int *)&iReadLen2);

    if (!_BLBDATA_62_FindFrameHead(pReadPtr1, iReadLen1, pReadPtr2, iReadLen2, (int *)&pos)) {
        LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }
    LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);

    LBUF_Unlock(pHandle->dwLBUFHandle);

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    usedSize = LBUF_GetUsedSize(pHandle->dwLBUFHandle);
    if (usedSize < headLen) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    preReadLen = headLen;
    if (!LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stFrameHead_62, &preReadLen, 0, 0) || preReadLen < headLen) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

//    #if 1
//        do {
//            FHNP_62_FrameHead_t stTemp;
//            if (headLen + stFrameHead_62.framelen + headLen > usedSize)
//            {
//                LOGE("帧不完整 1");
//                LBUF_Unlock(pHandle->dwLBUFHandle);
//                return 0;
//            }
//            preReadLen = headLen;
//            if (!LBUF_PreRead(pHandle->dwLBUFHandle, (char*)&stTemp, &preReadLen, headLen+stFrameHead_62.framelen, 0)
//                || preReadLen < headLen)
//            {
//                LOGE("帧不完整 2");
//                LBUF_Unlock(pHandle->dwLBUFHandle);
//                return 0;
//            }
//            if (!_BLBDATA_IsFrameHead(stTemp.FrmHd[0], stTemp.FrmHd[1], stTemp.FrmHd[2], stTemp.FrmHd[3]))
//            {
//                LOGE("帧不完整 3");
//                LBUF_SetReadPos(pHandle->dwLBUFHandle, headLen, 0);
//                LBUF_Unlock(pHandle->dwLBUFHandle);
//                return 0;
//            }
//        } while (0);
//    #endif

    if (headLen + stFrameHead_62.framelen > usedSize) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    memcpy(pFrameHead, &stFrameHead_62, sizeof(stFrameHead_62));
    memcpy(pFrameHead->reserve, stFrameHead_62.reserve, sizeof(stFrameHead_62.reserve));

    if (0xa0 == pFrameHead->FrmHd[3] || 0xa1 == pFrameHead->FrmHd[3] || 0xa2 == pFrameHead->FrmHd[3] ||
        0xa4 == pFrameHead->FrmHd[3]) {
        if (0 == pHandle->timestamp) {
            pHandle->timestamp = pFrameHead->timestamp;
            pHandle->frame_num = pFrameHead->frmnum;
        } else {
            if ((unsigned char)(pHandle->frame_num + 1) != (unsigned char)(pFrameHead->frmnum)) {
            }

            pHandle->timestamp = pFrameHead->timestamp;
            pHandle->frame_num = pFrameHead->frmnum;
        }
    }

    LBUF_SetReadPos(pHandle->dwLBUFHandle, headLen, 0);

    preReadLen = pFrameHead->framelen;
    LBUF_PreRead(pHandle->dwLBUFHandle, pFrame, &preReadLen, 0, 0);
    LBUF_SetReadPos(pHandle->dwLBUFHandle, preReadLen, 0);

    LBUF_Unlock(pHandle->dwLBUFHandle);

    return 1;
}

unsigned char _BLBDATA_63_GetOneFrame(BLHANDLE dwHandle, char *pHead, char *pFrame, unsigned char bIsIFrame) {
    unsigned int pos = 0;
    unsigned int preReadLen = 0;
    unsigned int usedSize = 0;
    char *pReadPtr1 = NULL;
    int iReadLen1 = 0;
    char *pReadPtr2 = NULL;
    int iReadLen2 = 0;
    FHNP_62_FrameHead_t stFrameHead_62;
    unsigned int headLen = sizeof(FHNP_62_FrameHead_t);
    FHNP_Dev_FrameHead_t *pFrameHead = (FHNP_Dev_FrameHead_t *)pHead;
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;

    if (!pHandle)
        return 0;

    if (LBUF_GetUsedSize(pHandle->dwLBUFHandle) < headLen)
        return 0;

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    LBUF_AdvGetReadPtr(pHandle->dwLBUFHandle, &pReadPtr1, (unsigned int *)&iReadLen1, &pReadPtr2,
                       (unsigned int *)&iReadLen2);

    if (!_BLBDATA_62_FindFrameHead(pReadPtr1, iReadLen1, pReadPtr2, iReadLen2, (int *)&pos)) {
        LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    LBUF_SetReadPos(pHandle->dwLBUFHandle, pos, 0);

    LBUF_Unlock(pHandle->dwLBUFHandle);

    //////////////////////////////////////////////////////////////////////////

    LBUF_Lock(pHandle->dwLBUFHandle);

    usedSize = LBUF_GetUsedSize(pHandle->dwLBUFHandle);
    if (usedSize < headLen) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    preReadLen = headLen;
    if (!LBUF_PreRead(pHandle->dwLBUFHandle, (char *)&stFrameHead_62, &preReadLen, 0, 0) || preReadLen < headLen) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    if (headLen + stFrameHead_62.framelen > usedSize) {
        LBUF_Unlock(pHandle->dwLBUFHandle);
        return 0;
    }

    memcpy(pFrameHead, &stFrameHead_62, sizeof(stFrameHead_62));
    pFrameHead->reserve[3] = stFrameHead_62.frmnum;

    if (0xa0 == pFrameHead->FrmHd[3] || 0xa1 == pFrameHead->FrmHd[3] || 0xa2 == pFrameHead->FrmHd[3]) {
        if (0 == pHandle->timestamp) {
            pHandle->timestamp = pFrameHead->timestamp;
            pHandle->frame_num = pFrameHead->frmnum;
        } else {
            if ((unsigned char)(pHandle->frame_num + 1) != (unsigned char)(pFrameHead->frmnum)) {
            }

            pHandle->timestamp = pFrameHead->timestamp;
            pHandle->frame_num = pFrameHead->frmnum;
        }
    }

    {
        LBUF_SetReadPos(pHandle->dwLBUFHandle, headLen, 0);

        preReadLen = pFrameHead->framelen;
        LBUF_PreRead(pHandle->dwLBUFHandle, pFrame, &preReadLen, 0, 0);
        LBUF_SetReadPos(pHandle->dwLBUFHandle, preReadLen, 0);
    }

    LBUF_Unlock(pHandle->dwLBUFHandle);

    return 1;
}


BLHANDLE BLBDATA_Create(unsigned int dwBufType, unsigned int dwMemSize) {
    BLBDATA_t *pHandle = (BLBDATA_t *)malloc(sizeof(BLBDATA_t));
    if (!pHandle)
        return 0;

    memset(pHandle, 0, sizeof(BLBDATA_t));

    pHandle->dwLBUFHandle = LBUF_Create(dwMemSize);
    if (!pHandle->dwLBUFHandle) {
        free(pHandle);
        return 0;
    }

    pHandle->bBufIsOver = 0;
    pHandle->dwBufIsOver = 0;
    pHandle->dwBufType = dwBufType;

    return (BLHANDLE)pHandle;
}

unsigned char BLBDATA_Destory(BLHANDLE dwHandle) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    LBUF_Destory(pHandle->dwLBUFHandle);
    free(pHandle);
    return 1;
}

unsigned char BLBDATA_Clear(BLHANDLE dwHandle) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    LBUF_Clear(pHandle->dwLBUFHandle);
    return 1;
}

unsigned char BLBDATA_Write(BLHANDLE dwHandle, char *pSrcBuf, unsigned int dwWriteLen) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_Write(pHandle->dwLBUFHandle, pSrcBuf, dwWriteLen);
}


unsigned char BLBDATA_GetOneFrame(BLHANDLE dwHandle, char *pHead, char *pFrame, unsigned char bIsIFrame) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle){
         OH_LOG_FATAL(LOG_APP, "帧数据 循环buff为0");
        return 0;
    }
       
    
    if (pHandle->dwBufType == BLBDATA_TYPE_61_FRAME) {

        return _BLBDATA_61_GetOneFrame(dwHandle, pHead, pFrame, bIsIFrame);
    }

    if (pHandle->dwBufType == BLBDATA_TYPE_81_FRAME) {
       
        return _BLBDATA_81_GetOneFrame(dwHandle, pHead, pFrame, bIsIFrame);
    }

    if (pHandle->dwBufType == BLBDATA_TYPE_62_FRAME) {

        return _BLBDATA_62_GetOneFrame(dwHandle, pHead, pFrame, bIsIFrame);
    }

    if (pHandle->dwBufType == BLBDATA_TYPE_63_FRAME) {

        return _BLBDATA_63_GetOneFrame(dwHandle, pHead, pFrame, bIsIFrame);
    }

    return 0;
}


unsigned char BLBDATA_SetReadPos(BLHANDLE dwHandle, unsigned int dwRead, unsigned char bLock) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_SetReadPos(pHandle->dwLBUFHandle, dwRead, bLock);
}

unsigned char BLBDATA_Lock(BLHANDLE dwHandle) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_Lock(pHandle->dwLBUFHandle);
}

unsigned char BLBDATA_Unlock(BLHANDLE dwHandle) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_Unlock(pHandle->dwLBUFHandle);
}

unsigned char BLBDATA_AdvGetWritePtr(BLHANDLE dwHandle, char **ppWritePtr1, unsigned int *pWriteLen1,
                                     char **ppWritePtr2, unsigned int *pWriteLen2) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_AdvGetWritePtr(pHandle->dwLBUFHandle, ppWritePtr1, pWriteLen1, ppWritePtr2, pWriteLen2);
}

unsigned char BLBDATA_AdvSetWritePos(BLHANDLE dwHandle, unsigned int dwWriteLen) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_AdvSetWritePos(pHandle->dwLBUFHandle, dwWriteLen);
}

unsigned char BLBDATA_AdvGetReadPtr(BLHANDLE dwHandle, char **ppReadPtr1, unsigned int *pReadLen1, char **ppReadPtr2,
                                    unsigned int *pReadLen2) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_AdvGetReadPtr(pHandle->dwLBUFHandle, ppReadPtr1, pReadLen1, ppReadPtr2, pReadLen2);
}

unsigned int BLBDATA_GetUsedSize(BLHANDLE dwHandle) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_GetUsedSize(pHandle->dwLBUFHandle);
}

unsigned int BLBDATA_GetFreeSize(BLHANDLE dwHandle) {
    BLBDATA_t *pHandle = (BLBDATA_t *)dwHandle;
    if (!pHandle)
        return 0;
    return LBUF_GetNoUsedSize(pHandle->dwLBUFHandle);
}
