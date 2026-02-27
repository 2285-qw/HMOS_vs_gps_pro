//
// Created on 2025/11/20.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef VSGPSPRO_NAPI_H
#define VSGPSPRO_NAPI_H

#endif //VSGPSPRO_NAPI_H

#include "napi/native_api.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * 基础数据类型定义（对应JNI中的j类型）
 */
/* Primitive types that match up with Java equivalents. */
typedef uint8_t  jboolean; /* unsigned 8 bits */
typedef int8_t   jbyte;    /* signed 8 bits */
typedef uint16_t jchar;    /* unsigned 16 bits */
typedef int16_t  jshort;   /* signed 16 bits */
typedef int32_t  jint;     /* signed 32 bits */
typedef int64_t  jlong;    /* signed 64 bits */
typedef float    jfloat;   /* 32-bit IEEE 754 */
typedef double   jdouble;  /* 64-bit IEEE 754 */

/* "cardinal indices and sizes" */
typedef jint     jsize;

#ifdef __cplusplus
/*
 * Reference types, in C++
 */


/**
 * 虚拟机接口（对应JavaVM）
 */
typedef struct {
    napi_status (*GetEnv)(void** env, uint32_t version);
    napi_status (*AttachCurrentThread)(void** env, void* args);
    napi_status (*DetachCurrentThread)();
} NAPIVMInterface;

typedef struct {
    const NAPIVMInterface* functions;
} NAPIVM;



#ifdef __cplusplus
}
#endif

#endif // HARMONY_NAPI_WRAPPER_H