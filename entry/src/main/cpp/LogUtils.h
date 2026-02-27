//
// Created by XiaoShu on 1/20/21.
//
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag

#define LOGE(...)  if(getShowLogTag()) \
     OH_LOG_ERROR(LOG_DOMAIN, LOG_TAG, "Error: file open failed, path=%s", "/data/test.txt");

#define LOGI(...)  if(getShowLogTag()) \
    HILOG_INFO(LOG_DOMAIN, TAG, __VA_ARGS__)

#define LOGW(...)  if(getShowLogTag()) \
    HILOG_WARN(LOG_DOMAIN, TAG, __VA_ARGS__)

#define LOGF(...)  if(getShowLogTag()) \
    HILOG_FATAL(LOG_DOMAIN, TAG, __VA_ARGS__)

#define LOGD(...)  if(getShowLogTag()) \
    HILOG_DEBUG(LOG_DOMAIN, TAG, __VA_ARGS__)

int getShowLogTag();
void setShowLog(const int boo);
long getCurrentTime();
