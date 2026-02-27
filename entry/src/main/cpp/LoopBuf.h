#ifndef _LOOP_BUF_H_
#define _LOOP_BUF_H_

#include <cstdint>
typedef void*   LBUFHANDLE;

LBUFHANDLE LBUF_Create(unsigned int dwMemSize);
unsigned char LBUF_Destory(LBUFHANDLE dwLBUFHandle);

unsigned char LBUF_Write(LBUFHANDLE dwLBUFHandle, char* pSrcBuf, unsigned int dwWriteLen);
unsigned char LBUF_Read(LBUFHANDLE dwLBUFHandle, char* pDstBuf, unsigned int* pReadLen);
unsigned char LBUF_Read1(LBUFHANDLE dwLBUFHandle, char* pDstBuf, uint16_t* pReadLen);

unsigned char LBUF_PreRead(LBUFHANDLE dwLBUFHandle, char* pDstBuf, unsigned int* pReadLen, unsigned int dwOffset, unsigned char bLock);

unsigned char LBUF_SetReadPos(LBUFHANDLE dwLBUFHandle, unsigned int dwRead, unsigned char bLock);

unsigned char LBUF_GetBufStatus(LBUFHANDLE dwLBUFHandle);

unsigned char LBUF_Clear(LBUFHANDLE dwLBUFHandle);

unsigned int  LBUF_GetUsedSize(LBUFHANDLE dwLBUFHandle);
unsigned int  LBUF_GetNoUsedSize(LBUFHANDLE dwLBUFHandle);

char* LBUF_GetPtr(LBUFHANDLE dwLBUFHandle);

unsigned char LBUF_Lock(LBUFHANDLE dwLBUFHandle);
unsigned char LBUF_Unlock(LBUFHANDLE dwLBUFHandle);

unsigned int  LBUF_MallocBuf(LBUFHANDLE dwLBUFHandle, char** ppBuf);

unsigned char LBUF_AdvGetWritePtr(LBUFHANDLE dwLBUFHandle, char** ppWritePtr1, unsigned int* pWriteLen1, char** ppWritePtr2, unsigned int* pWriteLen2);
unsigned char LBUF_AdvSetWritePos(LBUFHANDLE dwLBUFHandle, unsigned int dwWriteLen);
unsigned char LBUF_AdvGetReadPtr(LBUFHANDLE dwLBUFHandle, char** ppReadPtr1, unsigned int* pReadLen1, char** ppReadPtr2, unsigned int* pReadLen2);


#endif
