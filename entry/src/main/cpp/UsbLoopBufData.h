//
// Created by Vison on 2023/12/16.
//

#ifndef VISONNDK_USBLOOPBUFDATA_H
#define VISONNDK_USBLOOPBUFDATA_H

typedef void*   USBHANDLE;

USBHANDLE USBDATA_Create(unsigned int memSize);
unsigned char USBDATA_Destroy(USBHANDLE handle);
unsigned char USBDATA_Clear(USBHANDLE handle);

unsigned char USBDATA_Write(USBHANDLE handle, char* pSrcBuf, unsigned int dwWriteLen);
unsigned char USBDATA_GetOneFrame(USBHANDLE handle, char* pHead, char* pFrame);
unsigned char USBDATA_Read(USBHANDLE handle, char* pDstBuf, unsigned int* pReadLen);

unsigned char USBDATA_AdvGetWritePtr(USBHANDLE handle, char** ppWritePtr1, unsigned int* pWriteLen1, char** ppWritePtr2, unsigned int* pWriteLen2);
unsigned char USBDATA_AdvSetWritePos(USBHANDLE handle, unsigned int dwWriteLen);

unsigned char USBDATA_Lock(USBHANDLE handle);
unsigned char USBDATA_Unlock(USBHANDLE handle);

#endif //VISONNDK_USBLOOPBUFDATA_H
