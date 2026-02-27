#ifndef _CODE_LOCK_H_
#define _CODE_LOCK_H_

#if defined(WIN32)
#   include <windows.h>
#   define CODELOCK        CRITICAL_SECTION
#elif defined(_ECOS_)
#   include <cyg/kernel/kapi.h>
#   define CODELOCK        cyg_mutex_t
#elif defined(_MIPSEL_)
#   include <pthread.h>
#   define CODELOCK        pthread_mutex_t
#else
#   include <pthread.h>
#   define CODELOCK        pthread_mutex_t
#endif

extern void CreateCodeLock(CODELOCK* pLock);
extern void DestoryCodeLock(CODELOCK* pLock);
extern void CodeLock(CODELOCK* pLock);
extern void CodeUnlock(CODELOCK* pLock);

#endif
