#include "CodeLock.h"

#if defined(WIN32)

void CreateCodeLock(CODELOCK* pLock)
{
    InitializeCriticalSection(pLock);
}

void DestoryCodeLock(CODELOCK* pLock)
{
    DeleteCriticalSection(pLock);
}

void CodeLock(CODELOCK* pLock)
{
    EnterCriticalSection(pLock);
}

void CodeUnlock(CODELOCK* pLock)
{
    LeaveCriticalSection(pLock);
}

#elif defined(_ECOS_)

void CreateCodeLock(CODELOCK* pLock)
{
    cyg_mutex_init(pLock);
}

void DestoryCodeLock(CODELOCK* pLock)
{
    cyg_mutex_destroy(pLock);
}

void CodeLock(CODELOCK* pLock)
{
    cyg_mutex_lock(pLock);
}

void CodeUnlock(CODELOCK* pLock)
{
    cyg_mutex_unlock(pLock);
}

#elif defined(_MIPSEL_)

void CreateCodeLock(CODELOCK* pLock)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE_NP);
    pthread_mutex_init(pLock, &attr);
    pthread_mutexattr_destroy(&attr);
}

void DestoryCodeLock(CODELOCK* pLock)
{
    pthread_mutex_unlock(pLock); 
    pthread_mutex_destroy(pLock);
}

void CodeLock(CODELOCK* pLock)
{
    pthread_mutex_lock(pLock);
}

void CodeUnlock(CODELOCK* pLock)
{
    pthread_mutex_unlock(pLock);
}

#else

//extern int pthread_mutexattr_settype (__const pthread_mutexattr_t *__restrict
//                                      __attr, int  __kind);

#if defined(__APPLE__)
    #define PTHREAD_MUTEX_FAST_NP       PTHREAD_MUTEX_NORMAL
    #define PTHREAD_MUTEX_RECURSIVE_NP  PTHREAD_MUTEX_RECURSIVE
    #define PTHREAD_MUTEX_ERRORCHECK_NP PTHREAD_MUTEX_ERRORCHECK
#endif


void CreateCodeLock(CODELOCK* pLock)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(pLock, &attr);
    pthread_mutexattr_destroy(&attr);
}

void DestoryCodeLock(CODELOCK* pLock)
{
    pthread_mutex_unlock(pLock); 
    pthread_mutex_destroy(pLock);
}

void CodeLock(CODELOCK* pLock)
{
    pthread_mutex_lock(pLock);
}

void CodeUnlock(CODELOCK* pLock)
{
    pthread_mutex_unlock(pLock);
}

#endif
