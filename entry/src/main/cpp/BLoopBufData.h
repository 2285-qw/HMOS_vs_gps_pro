#ifndef _LOOP_BUF_DATA_H_
#define _LOOP_BUF_DATA_H_

#include <stdio.h>

#define BLBDATA_TYPE_61_FRAME   1
#define BLBDATA_TYPE_81_FRAME   7
#define BLBDATA_TYPE_62_FRAME   13
#define BLBDATA_TYPE_63_FRAME   14

typedef void*   BLHANDLE;

BLHANDLE BLBDATA_Create(unsigned int dwBufType, unsigned int dwMemSize);
unsigned char BLBDATA_Destory(BLHANDLE dwHandle);
unsigned char BLBDATA_Clear(BLHANDLE dwHandle);

unsigned char BLBDATA_GetOneFrame(BLHANDLE dwHandle, char* pHead, char* pFrame, unsigned char bIsIFrame);
unsigned char BLBDATA_Write(BLHANDLE dwHandle, char* pSrcBuf, unsigned int dwWriteLen);
unsigned char BLBDATA_SetReadPos(BLHANDLE dwHandle, unsigned int dwRead, unsigned char bLock);

unsigned char BLBDATA_Lock(BLHANDLE dwHandle);
unsigned char BLBDATA_Unlock(BLHANDLE dwHandle);
unsigned char BLBDATA_AdvGetWritePtr(BLHANDLE dwHandle, char** ppWritePtr1, unsigned int* pWriteLen1, char** ppWritePtr2, unsigned int* pWriteLen2);
unsigned char BLBDATA_AdvSetWritePos(BLHANDLE dwHandle, unsigned int dwWriteLen);
unsigned char BLBDATA_AdvGetReadPtr(BLHANDLE dwHandle, char** ppReadPtr1, unsigned int* pReadLen1, char** ppReadPtr2, unsigned int* pReadLen2);

unsigned int  BLBDATA_GetUsedSize(BLHANDLE dwHandle);
unsigned int  BLBDATA_GetFreeSize(BLHANDLE dwHandle);

#endif
