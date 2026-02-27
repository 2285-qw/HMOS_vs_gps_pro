#include "LoopBuf.h"
#include "CodeLock.h"
#include <hilog/log.h>
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag

#ifdef WIN32
#   include <windows.h>

#else
#   include <stdlib.h>
#   include <string.h>
#endif

typedef struct 
{
    CODELOCK mutex;
    unsigned int dwCurRead;
	unsigned int dwCurWrite;
	unsigned int dwSizeInUse;
	unsigned int dwBufSize;
	char *pBuf;
}LBUF_t;

LBUFHANDLE LBUF_Create(unsigned int dwMemSize)
{
    LBUF_t* pHandle = (LBUF_t*)malloc(sizeof(LBUF_t));
    if (!pHandle || 0 == dwMemSize){
        free(pHandle); // 释放内存
        pHandle = nullptr; // 避免野指针
        return 0;
    }

    memset(pHandle, 0, sizeof(LBUF_t));

    pHandle->pBuf = (char*)malloc(dwMemSize);
    if (!pHandle->pBuf)
    {
        free(pHandle);
        return 0;
    }

    pHandle->dwCurRead = 0;
    pHandle->dwCurWrite = 0;
    pHandle->dwSizeInUse = 0;
    pHandle->dwBufSize = dwMemSize;
    CreateCodeLock(&pHandle->mutex);

    return (LBUFHANDLE)pHandle;
}

unsigned char LBUF_Destory(LBUFHANDLE dwLBUFHandle)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    if (pHandle->pBuf)
        free(pHandle->pBuf);
    DestoryCodeLock(&pHandle->mutex);
    free(pHandle);
    
    return 0;
}

// 函数声明：向环形缓冲区写入数据
unsigned char LBUF_Write(LBUFHANDLE dwLBUFHandle, char* pSrcBuf, unsigned int dwWriteLen)
{
    unsigned int tmpSize = 0; // 用于临时存储需要写入的字节大小
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle; // 将句柄转换为LBUF_t结构体指针

    // 检查句柄是否有效
    if (!pHandle)
        return 0;

    // 检查源缓冲区指针和写入长度是否有效
    if (!pSrcBuf || 0 == dwWriteLen)
        return 0;

    // 上锁确保数据操作的原子性
    CodeLock(&pHandle->mutex);

    // 检查写入长度是否超出缓冲区剩余空间
    if (dwWriteLen > pHandle->dwBufSize - pHandle->dwSizeInUse)
    {
        // 清空缓冲区
        LBUF_Clear(dwLBUFHandle);

        // 解锁
        CodeUnlock(&pHandle->mutex);
        return 0;
    }

    // 如果写入位置加上写入长度不超过缓冲区大小
    if (pHandle->dwCurWrite + dwWriteLen <= pHandle->dwBufSize)
    {
        // 直接写入数据
        memcpy(pHandle->pBuf + pHandle->dwCurWrite, pSrcBuf, dwWriteLen);
        // 更新写入位置
        pHandle->dwCurWrite  += dwWriteLen;
        // 更新已经使用的大小
        pHandle->dwSizeInUse += dwWriteLen;
        // 如果写入位置到达缓冲区末尾，将其重置为0，实现循环
        if (pHandle->dwCurWrite == pHandle->dwBufSize)
        {
            pHandle->dwCurWrite = 0;
        }
    }
        // 如果写入位置加上写入长度将超过缓冲区大小
    else
    {
        // 计算从当前写入位置到缓冲区末尾的剩余空间
        tmpSize = pHandle->dwBufSize - pHandle->dwCurWrite;
        // 先写入到缓冲区末尾
        memcpy(pHandle->pBuf + pHandle->dwCurWrite, pSrcBuf, tmpSize);
        // 重置写入位置，从头开始写入剩余数据
        pHandle->dwCurWrite = dwWriteLen - tmpSize;
        // 写入剩余数据
        memcpy(pHandle->pBuf, pSrcBuf + tmpSize, dwWriteLen - tmpSize);
        // 更新已经使用的大小
        pHandle->dwSizeInUse += dwWriteLen;
    }

    // 解锁
    CodeUnlock(&pHandle->mutex);

    // 返回成功标识
    return 1;
}

// 函数声明：从环形缓冲区读取数据
unsigned char LBUF_Read(LBUFHANDLE dwLBUFHandle, char* pDstBuf, unsigned int* pReadLen)
{
    unsigned int tmpSize = 0; // 用于临时存储需要读取的字节数
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle; // 将句柄转换为LBUF_t结构体指针

    // 检查句柄是否有效
    if (!pHandle)
        return 0;

    // 检查目标缓冲区指针和读取长度是否有效
    if (!pDstBuf || 0 == *pReadLen)
        return 0;

    // 上锁确保数据操作的原子性
    CodeLock(&pHandle->mutex);

    // 检查请求的读取长度是否超出缓冲区中可用数据的长度
    if (*pReadLen > pHandle->dwSizeInUse)
    {
        // 将读取长度调整为当前可用数据的长度
        *pReadLen = pHandle->dwSizeInUse;
        // 解锁
        CodeUnlock(&pHandle->mutex);
        // 返回0，表示读取长度被调整
        return 0;
    }

    // 如果读取位置加上读取长度不超过缓冲区大小
    if (pHandle->dwCurRead + *pReadLen <= pHandle->dwBufSize)
    {
        // 直接读取数据到目标缓冲区
        memcpy(pDstBuf, pHandle->pBuf + pHandle->dwCurRead, *pReadLen);
        // 更新读取位置
        pHandle->dwCurRead	 += *pReadLen;
        // 更新已经使用数据的大小
        pHandle->dwSizeInUse -= *pReadLen;
        // 如果读取位置到达缓冲区末尾，将其重置为0，实现循环
        if (pHandle->dwCurRead == pHandle->dwBufSize)
        {
            pHandle->dwCurRead = 0;
        }
    }
        // 如果读取位置加上读取长度将超过缓冲区大小
    else
    {
        // 计算从当前读取位置到缓冲区末尾的剩余空间
        tmpSize = pHandle->dwBufSize - pHandle->dwCurRead;
        // 先读取到缓冲区末尾的数据
        memcpy(pDstBuf, pHandle->pBuf + pHandle->dwCurRead, tmpSize);
        // 重置读取位置，从头开始读取剩余数据
        pHandle->dwCurRead    = *pReadLen - tmpSize;
        // 更新已经使用数据的大小
        pHandle->dwSizeInUse -= *pReadLen;
        // 读取剩余数据
        memcpy(pDstBuf + tmpSize, pHandle->pBuf, pHandle->dwCurRead);
    }

    // 解锁
    CodeUnlock(&pHandle->mutex);

    // 返回1，表示成功读取
    return 1;
}

//错误
unsigned char LBUF_Read1(LBUFHANDLE dwLBUFHandle, char* pDstBuf, uint16_t* pReadLen)
{
    unsigned int tmpSize = 0;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    if (!pDstBuf || 0 == *pReadLen)
        return 0;

    CodeLock(&pHandle->mutex);

    //读取的长度如果大于 已存储数据的空间的话
    if (*pReadLen > pHandle->dwSizeInUse)
    {
//        *pReadLen = pHandle->dwSizeInUse;
        CodeUnlock(&pHandle->mutex);
        return 0;
    }

    //当前读取的数据偏移 + 要读取的长度的  未超过 存储空间总长，不需要转向头部读取
    if (pHandle->dwCurRead + *pReadLen <= pHandle->dwBufSize)
    {
        memcpy(pDstBuf, pHandle->pBuf + pHandle->dwCurRead, *pReadLen);
        //偏移读取的指针
        pHandle->dwCurRead     += *pReadLen;
        //更新已用空间值
        pHandle->dwSizeInUse -= *pReadLen;
        //已读取的指针如果再尾部直接更新到头部0位置
        if (pHandle->dwCurRead == pHandle->dwBufSize)
        {
            pHandle->dwCurRead = 0;
        }
    }
    else //当前读取的数据偏移 + 要读取的长度的  超过 存储空间总长，需要转向头部读取
    {
        //尾部剩余未读取的长度
        tmpSize = pHandle->dwBufSize - pHandle->dwCurRead;
        //读取尾部tmpSize长度数据
        memcpy(pDstBuf, pHandle->pBuf + pHandle->dwCurRead, tmpSize);
        //更新已读指针偏移
        pHandle->dwCurRead    = *pReadLen - tmpSize;
        //更新已用空间大小
        pHandle->dwSizeInUse -= *pReadLen;
        //剩余的数据从头部读取
        memcpy(pDstBuf + tmpSize, pHandle->pBuf, pHandle->dwCurRead);
    }

    CodeUnlock(&pHandle->mutex);

    return 1;
}

unsigned char LBUF_PreRead(LBUFHANDLE dwLBUFHandle, char* pDstBuf, unsigned int* pReadLen, unsigned int dwOffset, unsigned char bLock)
{
    unsigned int tmpSize, readPos;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    if (bLock)
        CodeLock(&pHandle->mutex);

	if (!pDstBuf || pHandle->dwSizeInUse == 0 || *pReadLen == 0 || pHandle->dwSizeInUse <= dwOffset)
	{
		*pReadLen = 0;
        if (bLock)
            CodeUnlock(&pHandle->mutex);

		return 0;
	}

	if (*pReadLen > pHandle->dwSizeInUse - dwOffset)
	{
		*pReadLen = pHandle->dwSizeInUse - dwOffset;
	}

	if (pHandle->dwCurRead + dwOffset < pHandle->dwBufSize)
	{
		readPos = pHandle->dwCurRead + dwOffset;
	}
	else
	{
		readPos = pHandle->dwCurRead + dwOffset - pHandle->dwBufSize;
	}
	
	if (readPos + *pReadLen <= pHandle->dwBufSize)
	{
		memcpy(pDstBuf, pHandle->pBuf + readPos, *pReadLen);
	}
	else
	{
		tmpSize = pHandle->dwBufSize - readPos;
		memcpy(pDstBuf, pHandle->pBuf + readPos, tmpSize);
		memcpy(pDstBuf + tmpSize, pHandle->pBuf, *pReadLen - tmpSize);
	}

	if (bLock)
	    CodeUnlock(&pHandle->mutex);

	return 1;
}

unsigned char LBUF_SetReadPos(LBUFHANDLE dwLBUFHandle, unsigned int dwRead, unsigned char bLock)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle || 0 == dwRead)
        return 0;

    if (bLock)
        CodeLock(&pHandle->mutex);

	if (dwRead > pHandle->dwSizeInUse)
	{
		LBUF_Clear(dwLBUFHandle);
		return 1;
	}

	if (pHandle->dwCurRead + dwRead <= pHandle->dwBufSize)
	{
		pHandle->dwCurRead	 += dwRead;
		pHandle->dwSizeInUse -= dwRead;
		if (pHandle->dwCurRead == pHandle->dwBufSize)
		{
			pHandle->dwCurRead = 0;
		}
	}
	else
	{
		pHandle->dwCurRead    = dwRead - (pHandle->dwBufSize - pHandle->dwCurRead);
		pHandle->dwSizeInUse -= dwRead;
	}
	
	if (bLock)
        CodeUnlock(&pHandle->mutex);
    
    return 1;
}

unsigned char LBUF_GetBufStatus(LBUFHANDLE dwLBUFHandle)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);

	if (3*pHandle->dwSizeInUse > 2*pHandle->dwBufSize)
	{
        CodeUnlock(&pHandle->mutex);
		return 0;
	}

    CodeUnlock(&pHandle->mutex);

	return 1;
}

unsigned char LBUF_Clear(LBUFHANDLE dwLBUFHandle)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);

    pHandle->dwCurRead = 0;
    pHandle->dwCurWrite = 0;
    pHandle->dwSizeInUse = 0;

    CodeUnlock(&pHandle->mutex);

    return 1;
}

unsigned int LBUF_GetUsedSize(LBUFHANDLE dwLBUFHandle)
{
    unsigned int dwSizeInUse = 0;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    //OH_LOG_FATAL(LOG_APP, "帧数据 LBUF_GetUsedSize 执行1");
    if (!pHandle){
        return 0;
    }
    //OH_LOG_FATAL(LOG_APP, "帧数据 LBUF_GetUsedSize 执行2");

    CodeLock(&pHandle->mutex);
	dwSizeInUse = pHandle->dwSizeInUse;
    CodeUnlock(&pHandle->mutex);

    return dwSizeInUse;
}
unsigned int LBUF_GetNoUsedSize(LBUFHANDLE dwLBUFHandle)
{
    unsigned int dwRet = 0;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);
	dwRet = pHandle->dwBufSize - pHandle->dwSizeInUse;
    CodeUnlock(&pHandle->mutex);

    return dwRet;
}

char* LBUF_GetPtr(LBUFHANDLE dwLBUFHandle)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;
    
    return pHandle->pBuf;
}

unsigned char LBUF_Lock(LBUFHANDLE dwLBUFHandle)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);
    return 1;
}

unsigned char LBUF_Unlock(LBUFHANDLE dwLBUFHandle)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeUnlock(&pHandle->mutex);
    return 1;
}

unsigned int LBUF_MallocBuf(LBUFHANDLE dwLBUFHandle, char** ppBuf)
{
    unsigned int dwRet = 0;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    if (!ppBuf)
        return 0;

    CodeLock(&pHandle->mutex);

	*ppBuf = pHandle->pBuf + pHandle->dwCurRead;
	if (pHandle->dwSizeInUse + pHandle->dwCurRead < pHandle->dwBufSize)
	{
        dwRet = pHandle->dwSizeInUse;
	}
	else
	{
		dwRet = pHandle->dwBufSize - pHandle->dwCurRead;
	}

    CodeUnlock(&pHandle->mutex);

    return dwRet;
}

unsigned char LBUF_AdvGetWritePtr(LBUFHANDLE dwLBUFHandle, char** ppWritePtr1, unsigned int* pWriteLen1, char** ppWritePtr2, unsigned int* pWriteLen2)
{
    unsigned int dwSizeNoUse = 0;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);

    dwSizeNoUse = pHandle->dwBufSize - pHandle->dwSizeInUse;

	if (0 == dwSizeNoUse)
	{
		CodeUnlock(&pHandle->mutex);
		return 0;
	}

    if (pHandle->dwCurWrite + dwSizeNoUse <= pHandle->dwBufSize)
    {
        *ppWritePtr1 = pHandle->pBuf + pHandle->dwCurWrite;
        *pWriteLen1 = dwSizeNoUse;
        
        *ppWritePtr2 = NULL;
        *pWriteLen2 = 0;
    }
    else
    {
        *ppWritePtr1 = pHandle->pBuf + pHandle->dwCurWrite;
        *pWriteLen1 = pHandle->dwBufSize - pHandle->dwCurWrite;

        *ppWritePtr2 = pHandle->pBuf;
        *pWriteLen2 = dwSizeNoUse - *pWriteLen1;
    }    

    CodeUnlock(&pHandle->mutex);

    return 1;
}

unsigned char LBUF_AdvSetWritePos(LBUFHANDLE dwLBUFHandle, unsigned int dwWriteLen)
{
    unsigned int tmpSize = 0;
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);

	if (dwWriteLen > (pHandle->dwBufSize-pHandle->dwSizeInUse))
	{
		CodeUnlock(&pHandle->mutex);
		return 0;
	}

	if (pHandle->dwCurWrite + dwWriteLen <= pHandle->dwBufSize)
	{
		pHandle->dwCurWrite  += dwWriteLen;
		pHandle->dwSizeInUse += dwWriteLen;
		if (pHandle->dwCurWrite == pHandle->dwBufSize)
		{
			pHandle->dwCurWrite = 0;
		}
	}
	else
	{
		tmpSize = pHandle->dwBufSize - pHandle->dwCurWrite;
		pHandle->dwCurWrite = dwWriteLen - tmpSize;
		pHandle->dwSizeInUse += dwWriteLen;
	}

    CodeUnlock(&pHandle->mutex);

    return 1;
}

unsigned char LBUF_AdvGetReadPtr(LBUFHANDLE dwLBUFHandle, char** ppReadPtr1, unsigned int* pReadLen1, char** ppReadPtr2, unsigned int* pReadLen2)
{
    LBUF_t* pHandle = (LBUF_t*)dwLBUFHandle;
    if (!pHandle)
        return 0;

    CodeLock(&pHandle->mutex);

    if (pHandle->dwCurRead + pHandle->dwSizeInUse <= pHandle->dwBufSize)
    {
        *ppReadPtr1 = pHandle->pBuf + pHandle->dwCurRead;
        *pReadLen1 = pHandle->dwSizeInUse;

        *ppReadPtr2 = NULL;
        *pReadLen2 = 0;
    }
    else
    {
        *ppReadPtr1 = pHandle->pBuf + pHandle->dwCurRead;
        *pReadLen1 = pHandle->dwBufSize - pHandle->dwCurRead;

        *ppReadPtr2 = pHandle->pBuf;
        *pReadLen2 = pHandle->dwSizeInUse - *pReadLen1;
    }

    CodeUnlock(&pHandle->mutex);

    return 1;
}
