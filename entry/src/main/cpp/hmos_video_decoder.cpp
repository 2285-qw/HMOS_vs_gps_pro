#include "hmos_video_decoder.h"
#include <hilog/log.h>
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200 // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"  // 全局tag宏，标识模块日志tag
#include <memory>
#include <string>
#include <cstring>
#include <chrono>
#include <algorithm>
#include <cmath>

// 只在文件开始时定义一次LOG_TAG
#ifndef LOG_TAG
#define LOG_TAG "VideoDecoder"
#endif

#define LOGD(fmt, ...) OH_LOG_Print(LOG_APP, LOG_DEBUG, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGI(fmt, ...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGE(fmt, ...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define LOGW(fmt, ...) OH_LOG_Print(LOG_APP, LOG_WARN, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)

// 像素格式常量
#define AV_PIXEL_FORMAT_NV21 1
#define AV_ERR_OK 0

// 辅助宏
#define CHECK_DECODER(decoder)                                                                                         \
    if (!decoder) {                                                                                                    \
        LOGE("Decoder is null");                                                                                       \
        return false;                                                                                                  \
    }
#define CHECK_DECODER_PTR(decoder)                                                                                     \
    if (!decoder) {                                                                                                    \
        LOGE("Decoder is null");                                                                                       \
        return;                                                                                                        \
    }

HmosVideoDecoder::HmosVideoDecoder()
    : decoder_(nullptr), format_(nullptr), surface_(nullptr), width_(0), height_(0), initialized_(false),
      started_(false), configured_(false), useHardware_(false), isLowVersion_(true), asyncRunning_(false),
      framesSubmitted_(0), framesDecoded_(0), framesRendered_(0) {
    LOGI("HmosVideoDecoder constructor");

    // 启动异步处理线程
    asyncRunning_ = true;
    asyncThread_ = std::thread([this]() { this->asyncProcessLoop(); });
    LOGI("Async processing thread started");
}

HmosVideoDecoder::~HmosVideoDecoder() {
    LOGI("HmosVideoDecoder destructor");

    // 停止异步线程
    {
        std::unique_lock<std::mutex> lock(inputMutex_);
        asyncRunning_ = false;
        inputCond_.notify_all();
    }

    if (asyncThread_.joinable()) {
        asyncThread_.join();
        LOGI("Async thread joined");
    }

    release();

    LOGI("Decoder destroyed, stats: submitted=%llu, decoded=%llu, rendered=%llu", framesSubmitted_, framesDecoded_,
         framesRendered_);
}

// 初始化解码器 设置解码类型
bool HmosVideoDecoder::initialize(const std::string &mimeType, int32_t width, int32_t height) {
    if (initialized_) {
        LOGI("Decoder already initialized");
        return true;
    }

    width_ = width;
    height_ = height;
    mimeType_ = mimeType;

    LOGI("初始化解码器: %{public}s,%{public}dx%{public}d", mimeType.c_str(), width, height);

    // 根据MIME类型选择对应的常量
    const char *mimeConst = nullptr;
    if (mimeType == "video/avc") {
        mimeConst = OH_AVCODEC_MIMETYPE_VIDEO_AVC; // h264
    } else if (mimeType == "video/hevc") {
        mimeConst = OH_AVCODEC_MIMETYPE_VIDEO_HEVC; // h265
    } else if (mimeType == "video/mp4v-es") {
        mimeConst = "video/mp4v-es";
    } else if (mimeType == "video/x-vnd.on2.vp8") {
        mimeConst = "video/x-vnd.on2.vp8";
    } else if (mimeType == "video/x-vnd.on2.vp9") {
        mimeConst = "video/x-vnd.on2.vp9";
    } else {
        LOGW("Unsupported MIME type: %s, using simulated mode", mimeType.c_str());
        initialized_ = true;
        started_ = true;
        return true;
    }

    // 检查硬件解码能力
    OH_AVCapability *hwCapability = OH_AVCodec_GetCapabilityByCategory(mimeConst,
                                                                       false, // 解码器
                                                                       HARDWARE);

    if (hwCapability != nullptr && OH_AVCapability_IsHardware(hwCapability)) {
        LOGI("解码硬解可用");
        useHardware_ = true;
        decoder_ = OH_VideoDecoder_CreateByMime(mimeConst);
    } else {
        // 尝试软件解码
        OH_AVCapability *swCapability = OH_AVCodec_GetCapabilityByCategory(mimeConst, false, SOFTWARE);

        if (swCapability != nullptr) {
            LOGI("解码软解可用");
            useHardware_ = false;
            decoder_ = OH_VideoDecoder_CreateByMime(mimeConst);
        }
    }

    if (!decoder_) {
        LOGW("Failed to create decoder, using simulated mode");
        initialized_ = true;
        started_ = true;
        return true;
    }

    // 配置解码器
    if (!configureDecoder()) {
        LOGE("Failed to configure decoder");
        OH_VideoDecoder_Destroy(decoder_);
        decoder_ = nullptr;
        initialized_ = true;
        started_ = true;
        return false;
    }

    // 注册回调函数
    OH_AVCodecCallback callback = {.onError = OnError,
                                   .onStreamChanged = OnStreamChanged,
                                   .onNeedInputBuffer = OnInputBufferAvailable,
                                   .onNewOutputBuffer = OnOutputBufferAvailable};

    int32_t ret = OH_VideoDecoder_RegisterCallback(decoder_, callback, this);
    if (ret != AV_ERR_OK) {
        LOGE("解码注册回调失败: %{public}d", ret);
        OH_VideoDecoder_Destroy(decoder_);
        decoder_ = nullptr;
        initialized_ = true;
        started_ = true;
        return true;
    }

    // 对于低版本，我们需要在回调中处理输出缓冲区
    isLowVersion_ = true;

    initialized_ = true;
    LOGI("解码器初始化成功 (Hardware: %{public}s, LowVersion: %{public}s)", useHardware_ ? "Yes" : "No",
         isLowVersion_ ? "Yes" : "No");

    return true;
}

bool HmosVideoDecoder::start() {
    LOGI("Starting decoder manually");

    if (!decoder_ || !initialized_ || started_) {
        LOGE("Decoder not initialized or already started");
        return false;
    }

    return startDecoder();
}

bool HmosVideoDecoder::setSurface(OHNativeWindow *nativeWindow) {

    OH_LOG_INFO(LOG_APP, "Surface set successfully============: %{public}s", decoder_ ? "true" : "false");
    OH_LOG_INFO(LOG_APP, "Surface set successfully============: %{public}s", initialized_ ? "true" : "false");
    if (!decoder_ || !initialized_) {
        LOGE("Decoder not initialized");
        return false;
    }

    surface_ = nativeWindow;

    if (surface_) {
        int32_t ret = OH_VideoDecoder_SetSurface(decoder_, surface_);
        if (ret != AV_ERR_OK) {
            LOGE("解码设置Surface失败: %{public}d", ret);
            surface_ = nullptr;
            return false;
        }
        LOGI("解码设置Surface成功");
    }

    // 启动解码器
    if (!started_) {
        return startDecoder();
    }

    return true;
}

/*bool HmosVideoDecoder::setSurfaceen(OHNativeWindow* nativeWindow) {

 // 1. 创建编码器实例（必须支持Surface）
OH_AVCodec* encoder = OH_VideoEncoder_CreateByName("hevc_hardware_encoder");

// 2. 配置关键参数（缺一不可！）
OH_AVFormat* format = OH_AVFormat_Create();
OH_AVFormat_SetIntValue(format, OH_MD_KEY_WIDTH, 1920);  // 宽度
OH_AVFormat_SetIntValue(format, OH_MD_KEY_HEIGHT, 1080); // 高度
OH_AVFormat_SetIntValue(format, OH_MD_KEY_PIXEL_FORMAT, AV_PIXEL_FORMAT_NV12); // 像素格式
OH_VideoEncoder_Configure(encoder, format);

// 3. 获取Surface对象（核心步骤）
OHNativeWindow* nativeWindow1 = nullptr;
OH_AVErrCode ret = OH_VideoEncoder_GetSurface(encoder, &nativeWindow);
if (ret != AV_ERR_OK || nativeWindow == nullptr) {
    // 错误处理：检查上述配置和调用顺序
}

// 4. 将nativeWindow绑定到数据源（如相机/屏幕录制）
// 示例：屏幕录制绑定
OH_AVScreenCaptureConfig config = {...};
OH_AVScreenCapture_SetOutputSurface(g_avCapture, nativeWindow);

// 5. 继续后续操作
OH_VideoEncoder_Prepare(encoder);
OH_VideoEncoder_Start(encoder);

    return true;
}*/


void HmosVideoDecoder::setCallbacks(OnFrameDecodedCallback frameCallback, OnErrorCallback errorCallback,
                                    OnFormatChangedCallback formatCallback) {

    frameCallback_ = frameCallback;
    errorCallback_ = errorCallback;
    formatChangedCallback_ = formatCallback;
}

bool HmosVideoDecoder::decodeFrame(const uint8_t *data, size_t size, int64_t timestamp, uint32_t flags) {
    // OH_LOG_ERROR(LOG_APP, "解码调用decodeFrame");

    if (!started_) {
        LOGE("解码器未启动");
        return false;
    }

    if (!decoder_) {
        LOGE("解码器未初始化");
        return false;
    }

    LOGD("Queueing frame for decoding: size=%{public}zu, timestamp=%{public}lld, flags=%{public}u", size, timestamp,
         flags);

    // 创建PendingInput，这会复制数据
    PendingInput input(data, size, timestamp, flags);

    {
        std::lock_guard<std::mutex> lock(inputMutex_);
        pendingInputs_.push_back(std::move(input)); // 使用移动语义
        inputCond_.notify_one();
    }
    framesSubmitted_++;
    HmosVideoDecoder::addRecordingData(data, size, timestamp, flags);
    return true;
}


VideoFramePtr HmosVideoDecoder::getDecodedFrame(int32_t timeoutMs) {
    LOGD("getDecodedFrame11111");
    if (decoder_ /*|| surface_ != nullptr*/) {
        // 如果使用Surface模式或模拟模式，从队列获取
        std::unique_lock<std::mutex> lock(frameMutex_);

        if (decodedFrames_.empty() && timeoutMs > 0) {
            // 等待指定的超时时间
            auto pred = [this]() { return !decodedFrames_.empty(); };

            if (timeoutMs == -1) {
                // 无限等待
                lock.unlock();
                // 等待输出可用的信号
                std::unique_lock<std::mutex> outputLock(outputMutex_);
                outputCond_.wait(outputLock, [this]() {
                    std::lock_guard<std::mutex> frameLock(frameMutex_);
                    LOGD("getDecodedFrame11111==empty1");
                    return !decodedFrames_.empty();
                });
                lock.lock();
            } else {
                // 有限等待
                lock.unlock();
                std::unique_lock<std::mutex> outputLock(outputMutex_);
                outputCond_.wait_for(outputLock, std::chrono::milliseconds(timeoutMs), [this]() {
                    std::lock_guard<std::mutex> frameLock(frameMutex_);
                    LOGD("getDecodedFrame11111==empty2");
                    return !decodedFrames_.empty();
                });
                lock.lock();
            }
        }

        if (decodedFrames_.empty()) {
            LOGD("getDecodedFrame11111==empty");
            return nullptr;
        }

        VideoFramePtr frame = decodedFrames_.front();
        decodedFrames_.pop_front();

        LOGD("Returning decoded frame: %dx%d, timestamp=%lld", frame->width, frame->height, frame->timestamp);
        return frame;
    }

    return nullptr;
}

void HmosVideoDecoder::flush() {
    LOGI("Flushing decoder");

    if (decoder_ && started_) {
        OH_VideoDecoder_Flush(decoder_);

        // 清空所有队列
        {
            std::lock_guard<std::mutex> lock(inputMutex_);
            pendingInputs_.clear();
            availableInputBuffers_.clear();
        }

        {
            std::lock_guard<std::mutex> lock(outputMutex_);
            availableOutputBuffers_.clear();
        }

        {
            std::lock_guard<std::mutex> lock(frameMutex_);
            decodedFrames_.clear();
        }

        LOGI("Decoder flushed");
    }
}

void HmosVideoDecoder::stop() {
    LOGI("Stopping decoder");

    if (decoder_ && started_) {
        OH_VideoDecoder_Stop(decoder_);
        started_ = false;
    }

    // 通知异步线程停止
    {
        std::lock_guard<std::mutex> lock(inputMutex_);
        asyncRunning_ = false;
        inputCond_.notify_all();
    }

    // 清空帧队列
    {
        std::lock_guard<std::mutex> lock(frameMutex_);
        decodedFrames_.clear();
    }

    LOGI("Decoder stopped");
}

void HmosVideoDecoder::release() {
    LOGI("Releasing decoder");

    stop();

    if (decoder_) {
        OH_VideoDecoder_Destroy(decoder_);
        decoder_ = nullptr;
    }

    if (format_) {
        OH_AVFormat_Destroy(format_);
        format_ = nullptr;
    }

    surface_ = nullptr;
    initialized_ = false;
    configured_ = false;

    LOGI("Decoder released");
}

// ==================== 静态回调函数 ====================

void HmosVideoDecoder::OnError(OH_AVCodec *codec, int32_t errorCode, void *userData) {
    LOGE("解码异常回调: %{public}d", errorCode);
    HmosVideoDecoder *decoder = static_cast<HmosVideoDecoder *>(userData);


    if (decoder && decoder->errorCallback_) {
        decoder->errorCallback_(errorCode);
    }
}

void HmosVideoDecoder::OnStreamChanged(OH_AVCodec *codec, OH_AVFormat *format, void *userData) {
    LOGE("解码数据流变化回调:");
    HmosVideoDecoder *decoder = static_cast<HmosVideoDecoder *>(userData);
    if (format && decoder) {
        int32_t width = 0, height = 0, pixelFormat = 0;
        OH_AVFormat_GetIntValue(format, OH_MD_KEY_WIDTH, &width);
        OH_AVFormat_GetIntValue(format, OH_MD_KEY_HEIGHT, &height);
        OH_AVFormat_GetIntValue(format, OH_MD_KEY_PIXEL_FORMAT, &pixelFormat);

        LOGI("Output format changed: %{public}dx%{public}d, pixel format: %{public}d", width, height, pixelFormat);

        // 更新解码器尺寸
        decoder->width_ = width;
        decoder->height_ = height;

        if (decoder->formatChangedCallback_) {
            decoder->formatChangedCallback_(width, height, pixelFormat);
        }
    }
}

void HmosVideoDecoder::OnInputBufferAvailable(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer, void *userData) {

    LOGI("解码输入回调index=%{public}u", index);
    HmosVideoDecoder *decoder = static_cast<HmosVideoDecoder *>(userData);
    if (decoder) {
        LOGD("解码存入缓冲区得可用索引: index=%{public}u", index);

        AvailableBuffer availBuffer;
        availBuffer.index = index;
        availBuffer.buffer = buffer;

        {
            std::lock_guard<std::mutex> lock(decoder->inputMutex_);
            decoder->availableInputBuffers_.push_back(availBuffer);
            decoder->inputCond_.notify_one();
        }
        // int32_t ret = OH_VideoDecoder_PushInputBuffer(codec, index);
    }
}

void HmosVideoDecoder::OnOutputBufferAvailable(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer, void *userData) {
    LOGD("解码输出回调OH_AVCodecOnNewOutputBuffer实现。");
    LOGI("解码输出回调OH_AVCodecOnNewOutputBuffer实现。");
    HmosVideoDecoder *decoder = static_cast<HmosVideoDecoder *>(userData);
    if (decoder) {
        LOGD("Output buffer available in callback: index=%u", index);

        // 对于低版本，直接在回调中处理输出缓冲区
        if (decoder->isLowVersion_) {
            // 在回调线程中直接处理，避免使用OH_VideoDecoder_GetOutputBuffer
            decoder->handleOutputBufferInCallback(index, buffer);
        } else {
            // 对于高版本，将缓冲区信息存入队列，由异步线程处理
            OutputBufferInfo info;
            info.index = index;
            info.buffer = buffer;

            {
                std::lock_guard<std::mutex> lock(decoder->outputMutex_);
                decoder->availableOutputBuffers_.push_back(info);
                decoder->outputCond_.notify_one();
            }
        }
    }
}

// ==================== 异步处理线程 ====================

void HmosVideoDecoder::asyncProcessLoop() {
    LOGI("Async processing thread started");

    while (asyncRunning_) {
        // 处理待处理的输入数据
        processPendingInputs();

        // 如果不是低版本，处理可用的输出缓冲区
        if (!isLowVersion_) {
            std::unique_lock<std::mutex> lock(outputMutex_);
            while (!availableOutputBuffers_.empty() && asyncRunning_) {
                OutputBufferInfo info = availableOutputBuffers_.front();
                availableOutputBuffers_.pop_front();
                lock.unlock();

                // 处理输出缓冲区
                processAvailableOutput(info.index, info.buffer);

                // 释放输出缓冲区
                OH_VideoDecoder_FreeOutputBuffer(decoder_, info.index);

                lock.lock();
            }
        }

        // 短暂休眠以避免CPU占用过高
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }

    LOGI("Async processing thread stopped");
}

bool HmosVideoDecoder::processPendingInputs() {
    std::unique_lock<std::mutex> lock(inputMutex_);

    // 等待输入缓冲区或待处理数据
    if (pendingInputs_.empty() || availableInputBuffers_.empty()) {
        // 等待条件变量，最多等待10ms
        inputCond_.wait_for(lock, std::chrono::milliseconds(10), [this]() {
            return !pendingInputs_.empty() && !availableInputBuffers_.empty() || !asyncRunning_;
        });

        if (!asyncRunning_) {
            return false;
        }

        if (pendingInputs_.empty() || availableInputBuffers_.empty()) {
            return false;
        }
    }


    // 获取待处理输入和可用缓冲区
    PendingInput input = std::move(pendingInputs_.front());
    pendingInputs_.pop_front();

    AvailableBuffer buffer = availableInputBuffers_.front();
    availableInputBuffers_.pop_front();

    lock.unlock();

    // 填充输入缓冲区
    if (!fillInputBuffer(buffer.index, buffer.buffer, input)) {
        LOGW("Failed to fill input buffer, requeueing input");
        lock.lock();
        pendingInputs_.push_front(std::move(input)); // 重新加入队列
        return false;
    }
    LOGW("解码提交数据缓冲区");
    // 提交输入缓冲区
    int32_t ret = OH_VideoDecoder_PushInputBuffer(decoder_, buffer.index);
    if (ret != AV_ERR_OK) {
        LOGE("解码提交输入缓冲区失败: %{public}d", ret);
        return false;
    }

    LOGD("解码输入缓冲区已推入: index=%{public}u, pts=%{public}lld, size=%{public}zu, flags=%{public}u", buffer.index,
         input.timestamp, input.data.size(), input.flags);
    return true;
}

void HmosVideoDecoder::processAvailableOutput(uint32_t index, OH_AVBuffer *buffer) {
    framesDecoded_++;

    if (surface_) {
        // Surface模式：渲染到Surface
        processOutputBufferToSurface(index, buffer);
        LOGE("urface模式11111111");

        framesRendered_++;
    } else {
        // 内存模式：创建VideoFrame
        VideoFramePtr frame = createVideoFrameFromBuffer(index, buffer);
        if (frame) {
            if (frameCallback_) {
                frameCallback_(frame);
            } else {
                std::lock_guard<std::mutex> lock(frameMutex_);
                decodedFrames_.push_back(frame);
                outputCond_.notify_one(); // 通知有新的帧可用
            }
        }
    }
}

void HmosVideoDecoder::handleOutputBufferInCallback(uint32_t index, OH_AVBuffer *buffer) {
    // 这个方法在回调线程中直接调用，避免使用OH_VideoDecoder_GetOutputBuffer

    // 获取缓冲区属性，检查是否为EOS
    OH_AVCodecBufferAttr attr;
    bool isEOS = false;
    if (OH_AVBuffer_GetBufferAttr(buffer, &attr) == AV_ERR_OK) {
        if (attr.flags & AVCODEC_BUFFER_FLAGS_EOS) {
            isEOS = true;
            LOGI("Received EOS frame in callback");
        }
    }

    if (isEOS) {
        // EOS帧处理
        if (errorCallback_) {
            errorCallback_(0); // 0表示正常结束
        }
        OH_VideoDecoder_FreeOutputBuffer(decoder_, index);
        return;
    }

    framesDecoded_++;

    if (surface_) {
        // Surface模式：直接在回调中渲染
        int32_t ret = OH_VideoDecoder_RenderOutputBuffer(decoder_, index);
        LOGE("urface模式22222222222");
        if (ret != AV_ERR_OK) {
            LOGE("Failed to render output buffer: %d", ret);
        } else {
            framesRendered_++;
            LOGD("Rendered frame to surface in callback: index=%u", index);
        }

        // 释放输出缓冲区
        OH_VideoDecoder_FreeOutputBuffer(decoder_, index);
    } else {
        // 内存模式：在回调中创建VideoFrame
        VideoFramePtr frame = createVideoFrameFromBuffer(index, buffer);

        LOGE("urface模式==================");
        if (frame) {
            LOGE("urface模式============11111111111");
            if (frameCallback_) {
                // 在回调线程中直接调用回调
                frameCallback_(frame);
            } else {
                // 存入队列
                std::lock_guard<std::mutex> lock(frameMutex_);
                decodedFrames_.push_back(frame);
                outputCond_.notify_one(); // 通知有新的帧可用
            }
        }

        // 释放输出缓冲区
        OH_VideoDecoder_FreeOutputBuffer(decoder_, index);
    }
}

void HmosVideoDecoder::processOutputBufferToSurface(uint32_t index, OH_AVBuffer *buffer) {
    if (!buffer || !surface_) {
        return;
    }

    int32_t ret = OH_VideoDecoder_RenderOutputBuffer(decoder_, index);
    if (ret != AV_ERR_OK) {
        LOGE("Failed to render output buffer: %d", ret);
    } else {
        LOGD("Rendered frame to surface: index=%u", index);
    }
}

VideoFramePtr HmosVideoDecoder::createVideoFrameFromBuffer(uint32_t index, OH_AVBuffer *buffer) {
    if (!buffer) {
        return nullptr;
    }

    // 获取输出格式
    OH_AVFormat *outputFormat = OH_VideoDecoder_GetOutputDescription(decoder_);

    int32_t width = width_, height = height_, pixelFormat = AV_PIXEL_FORMAT_NV21;
    if (outputFormat) {
        OH_AVFormat_GetIntValue(outputFormat, OH_MD_KEY_WIDTH, &width);
        OH_AVFormat_GetIntValue(outputFormat, OH_MD_KEY_HEIGHT, &height);
        OH_AVFormat_GetIntValue(outputFormat, OH_MD_KEY_PIXEL_FORMAT, &pixelFormat);
        OH_AVFormat_Destroy(outputFormat);
    }

    // 获取缓冲区属性
    OH_AVCodecBufferAttr attr;
    int64_t timestamp = 0;
    if (OH_AVBuffer_GetBufferAttr(buffer, &attr) == AV_ERR_OK) {
        timestamp = attr.pts;
    }

    // 获取缓冲区数据
    uint8_t *bufferData = OH_AVBuffer_GetAddr(buffer);
    int32_t bufferSize = OH_AVBuffer_GetCapacity(buffer);

    // 创建视频帧
    auto frame = std::make_shared<VideoFrame>(width, height, width, timestamp, pixelFormat);
    LOGW("解码把数据复制到缓冲区1");
    // 拷贝数据
    if (bufferData && bufferSize > 0 && !frame->data.empty()) {
        size_t copySize = std::min(frame->data.size(), static_cast<size_t>(bufferSize));
        memcpy(frame->data.data(), bufferData, copySize);
    } else {
        // 如果没有数据，生成测试图像
        generateTestImage(frame);
    }

    LOGD("解码已创建视频帧: %{public}dx%{public}d, timestamp=%{public}lld, size=%{public}zu", width, height, timestamp,
         frame->data.size());
    return frame;
}

// ==================== 辅助函数 ====================

bool HmosVideoDecoder::configureDecoder() {
    if (!decoder_ || configured_) {
        return false;
    }
    LOGD("解码执行configureDecoder");
    // 创建媒体格式
    format_ = OH_AVFormat_Create();
    if (!format_) {
        LOGE("Failed to create format");
        return false;
    }
    LOGD("解码执行configureDecoder11111");

    // 设置媒体格式参数
    const char *mimeConst = mimeType_.c_str();
    if (mimeType_ == "video/avc") {
        mimeConst = OH_AVCODEC_MIMETYPE_VIDEO_AVC;
    } else if (mimeType_ == "video/hevc") {
        mimeConst = OH_AVCODEC_MIMETYPE_VIDEO_HEVC;
    }

    OH_AVFormat_SetStringValue(format_, OH_MD_KEY_CODEC_MIME, mimeConst);
    OH_AVFormat_SetIntValue(format_, OH_MD_KEY_WIDTH, width_);
    OH_AVFormat_SetIntValue(format_, OH_MD_KEY_HEIGHT, height_);
    // OH_AVFormat_SetIntValue(format_, OH_MD_KEY_PIXEL_FORMAT, AV_PIXEL_FORMAT_NV21);

    // 配置解码器
    int32_t ret = OH_VideoDecoder_Configure(decoder_, format_);
    if (ret != AV_ERR_OK) {
        LOGE("Failed to configure decoder: %{public}d", ret);
        OH_AVFormat_Destroy(format_);
        format_ = nullptr;
        return false;
    }
    LOGD("解码执行configureDecoder2222222");

    configured_ = true;
    LOGI("Decoder configured successfully");
    return true;
}

bool HmosVideoDecoder::startDecoder() {
    if (!decoder_ || started_) {
        return false;
    }

    // 准备解码器
    int32_t ret = OH_VideoDecoder_Prepare(decoder_);
    if (ret != AV_ERR_OK) {
        LOGE("解码器准备失败r: %d", ret);
        return false;
    }

    // 启动解码器
    ret = OH_VideoDecoder_Start(decoder_);
    if (ret != AV_ERR_OK) {
        LOGE("解码器启动失败: %d", ret);
        return false;
    }

    started_ = true;
    LOGI("解码器已成功启动");
    return true;
}

bool HmosVideoDecoder::fillInputBuffer(uint32_t index, OH_AVBuffer *buffer, PendingInput &input) {
    if (!buffer) {
        return false;
    }

    // 处理EOS帧
    if (input.flags & AVCODEC_BUFFER_FLAGS_EOS) {
        LOGI("解码正在处理eos帧");

        OH_AVCodecBufferAttr attr;
        attr.size = 0;
        attr.offset = 0;
        attr.pts = input.timestamp;
        attr.flags = input.flags;

        if (OH_AVBuffer_SetBufferAttr(buffer, &attr) != AV_ERR_OK) {
            LOGE("Failed to set EOS buffer attributes");
            return false;
        }
        return true;
    }

    // 正常数据帧处理
    uint8_t *bufferData = OH_AVBuffer_GetAddr(buffer);
    int32_t bufferSize = OH_AVBuffer_GetCapacity(buffer);

    if (!bufferData || bufferSize <= 0) {
        LOGE("Invalid input buffer");
        return false;
    }

    size_t copySize = input.data.size();
    if (static_cast<int32_t>(copySize) > bufferSize) {
        LOGW("Data size (%zu) exceeds buffer capacity (%d), truncating", copySize, bufferSize);
        copySize = bufferSize;
    }

    // 拷贝数据
    if (copySize > 0 && !input.data.empty()) {
        LOGW("解码把数据复制到缓冲区2");
        memcpy(bufferData, input.data.data(), copySize);
    }


    // 设置缓冲区属性
    OH_AVCodecBufferAttr attr;
    attr.size = copySize;
    attr.offset = 0;
    attr.pts = input.timestamp;
    attr.flags = input.flags;

    if (OH_AVBuffer_SetBufferAttr(buffer, &attr) != AV_ERR_OK) {
        LOGE("Failed to set buffer attributes");
        return false;
    }


    return true;
}

void HmosVideoDecoder::generateTestImage(VideoFramePtr frame) {
    if (!frame || frame->data.empty()) {
        LOGE("Invalid frame in generateTestImage");
        return;
    }

    if (frame->width <= 0 || frame->height <= 0) {
        LOGE("Invalid frame dimensions: %dx%d", frame->width, frame->height);
        return;
    }

    // 计算NV21数据大小
    size_t ySize = frame->width * frame->height;
    size_t uvSize = ySize / 2;

    if (frame->data.size() < ySize + uvSize) {
        LOGE("Frame data buffer too small: %zu < %zu", frame->data.size(), ySize + uvSize);
        return;
    }

    uint8_t *yPlane = frame->data.data();
    uint8_t *uvPlane = yPlane + ySize;

    // 生成简单的测试图案（随时间变化）
    static int counter = 0;
    counter++;

    // 生成Y分量（亮度）
    for (int i = 0; i < frame->height; i++) {
        for (int j = 0; j < frame->width; j++) {
            // 创建简单的渐变图案
            int y = (i * 255 / frame->height) ^ (j * 255 / frame->width);
            y = (y + counter) % 256;
            yPlane[i * frame->width + j] = static_cast<uint8_t>(y);
        }
    }

    // 生成UV分量（色度）- NV21格式：VU交错存储
    for (int i = 0; i < frame->height / 2; i++) {
        for (int j = 0; j < frame->width / 2; j++) {
            // 简单的色度变化
            int u = (128 + 64 * sin(counter * 0.1 + i * 0.1));
            int v = (128 + 64 * cos(counter * 0.1 + j * 0.1));

            // 确保值在有效范围内
            u = (u < 0) ? 0 : ((u > 255) ? 255 : u);
            v = (v < 0) ? 0 : ((v > 255) ? 255 : v);

            // NV21格式：VU交错存储，每个2x2块共享一组UV
            int baseIndex = i * frame->width + j * 2;
            uvPlane[baseIndex] = static_cast<uint8_t>(v);     // V分量
            uvPlane[baseIndex + 1] = static_cast<uint8_t>(u); // U分量
        }
    }

    LOGD("Generated test image: %dx%d, counter=%d", frame->width, frame->height, counter);
}

// ==================== C接口实现 ====================

extern "C" {

void *hmos_video_decoder_create() {
    HmosVideoDecoder *decoder = new HmosVideoDecoder();
    LOGI("C API: Decoder created at %p", decoder);
    return static_cast<void *>(decoder);
}

bool hmos_video_decoder_initialize(void *decoder, const char *mimeType, int32_t width, int32_t height) {
    if (!decoder) {
        LOGE("C API: Invalid decoder pointer");
        return false;
    }

    HmosVideoDecoder *hmosDecoder = static_cast<HmosVideoDecoder *>(decoder);
    std::string mime(mimeType);

    LOGI("C API: Initializing decoder: %s, %dx%d", mimeType, width, height);
    return hmosDecoder->initialize(mime, width, height);
}

bool hmos_video_decoder_set_surface(void *decoder, void *nativeWindow) {
    if (!decoder) {
        LOGE("C API: Invalid decoder pointer");
        return false;
    }

    HmosVideoDecoder *hmosDecoder = static_cast<HmosVideoDecoder *>(decoder);
    return hmosDecoder->setSurface(static_cast<OHNativeWindow *>(nativeWindow));
}

bool hmos_video_decoder_decode_frame(void *decoder, uint8_t *data, size_t size, int64_t timestamp) {
    if (!decoder) {
        LOGE("C API: Invalid decoder pointer");
        return false;
    }

    HmosVideoDecoder *hmosDecoder = static_cast<HmosVideoDecoder *>(decoder);
    return hmosDecoder->decodeFrame(data, size, timestamp, AVCODEC_BUFFER_FLAGS_NONE);
}

void *hmos_video_decoder_get_frame(void *decoder) {
    if (!decoder) {
        LOGE("C API: Invalid decoder pointer");
        return nullptr;
    }

    HmosVideoDecoder *hmosDecoder = static_cast<HmosVideoDecoder *>(decoder);
    VideoFramePtr frame = hmosDecoder->getDecodedFrame(0);

    if (!frame) {
        return nullptr;
    }

    // 为了C接口兼容性，分配一个新的VideoFrame并深拷贝数据
    VideoFrame *rawFrame = new VideoFrame(*frame);
    return static_cast<void *>(rawFrame);
}

void hmos_video_decoder_free_frame(void *frame) {
    if (!frame) {
        LOGE("C API: Invalid frame pointer");
        return;
    }

    VideoFrame *videoFrame = static_cast<VideoFrame *>(frame);
    delete videoFrame;
}

void hmos_video_decoder_flush(void *decoder) {
    if (!decoder) {
        LOGE("C API: Invalid decoder pointer");
        return;
    }

    HmosVideoDecoder *hmosDecoder = static_cast<HmosVideoDecoder *>(decoder);
    hmosDecoder->flush();
}

void hmos_video_decoder_release(void *decoder) {
    if (!decoder) {
        LOGE("C API: Invalid decoder pointer");
        return;
    }

    HmosVideoDecoder *hmosDecoder = static_cast<HmosVideoDecoder *>(decoder);
    hmosDecoder->release();
    delete hmosDecoder;
    LOGI("C API: Decoder released");
}

bool hmos_video_decoder_is_supported(const char *mimeType) {
    // 根据MIME类型选择对应的常量
    const char *mimeConst = nullptr;
    std::string mime(mimeType);

    if (mime == "video/avc") {
        mimeConst = OH_AVCODEC_MIMETYPE_VIDEO_AVC;
    } else if (mime == "video/hevc") {
        mimeConst = OH_AVCODEC_MIMETYPE_VIDEO_HEVC;
    } else if (mime == "video/mp4v-es") {
        mimeConst = "video/mp4v-es";
    } else if (mime == "video/x-vnd.on2.vp8") {
        mimeConst = "video/x-vnd.on2.vp8";
    } else if (mime == "video/x-vnd.on2.vp9") {
        mimeConst = "video/x-vnd.on2.vp9";
    } else {
        LOGE("Unsupported MIME type: %s", mimeType);
        return false;
    }

    if (!mimeConst) {
        return false;
    }

    // 检查硬件加速支持
    OH_AVCapability *capability = OH_AVCodec_GetCapabilityByCategory(mimeConst,
                                                                     false, // 是否为编码器（false表示解码器）
                                                                     HARDWARE // 指定硬件编解码器类别
    );

    if (capability != nullptr) {
        bool hardwareSupported = OH_AVCapability_IsHardware(capability);
        if (hardwareSupported) {
            LOGI("Hardware acceleration supported for: %{public}s", mimeType);
            return true;
        }
    }

    // 如果硬件不支持，检查软件支持
    capability = OH_AVCodec_GetCapabilityByCategory(mimeConst,
                                                    false,   // 是否为编码器（false表示解码器）
                                                    SOFTWARE // 指定软件编解码器类别
    );

    if (capability != nullptr) {
        LOGI("Software decoder available for: %s", mimeType);
        return true;
    }

    LOGW("No decoder available for: %s", mimeType);
    return false;
}

/**
*fd沙箱路径地址
*
*/
// 码流录制视频
bool HmosVideoDecoder::StreamRecording(int32_t fd) {
    muxer_ = OH_AVMuxer_Create(fd, AV_OUTPUT_FORMAT_MPEG_4);

    OH_AVFormat *formatVideo = OH_AVFormat_Create();
    // 必填参数
    // 判断编码格式
    if (mimeType_ == "video/avc") {
        OH_AVFormat_SetStringValue(formatVideo, OH_MD_KEY_CODEC_MIME, OH_AVCODEC_MIMETYPE_VIDEO_AVC); // H.264
    } else if (mimeType_ == "video/hevc") {
        OH_AVFormat_SetStringValue(formatVideo, OH_MD_KEY_CODEC_MIME, OH_AVCODEC_MIMETYPE_VIDEO_HEVC); // H.265
    }

    OH_AVFormat_SetIntValue(formatVideo, OH_MD_KEY_WIDTH, 2560);
    OH_AVFormat_SetIntValue(formatVideo, OH_MD_KEY_HEIGHT,1440);
    // OH_AVFormat_SetDoubleValue(formatVideo, OH_MD_KEY_FRAME_RATE, 30.0);
    // OH_AVFormat_SetLongValue(formatVideo, OH_MD_KEY_BITRATE, 2000000);
    int32_t videoTrackIndex = -1;
    videoTrackId = OH_AVMuxer_AddTrack(muxer_, &videoTrackIndex, formatVideo);
    OH_AVFormat_Destroy(formatVideo); // 添加完成后，format 可销毁
    
    // 4. 启动封装器
    OH_AVErrCode result = OH_AVMuxer_Start(muxer_);
    if (result == AV_ERR_OK) {
        LOGI("路径创建: 启动成功");
    } else {
        // 启动失败，根据错误码进行相应的错误处理
        LOGI("路径创建: 启动失败");
    }
    isRecording_ = true;
    return true;
}

// 码流录制视频添加数据
bool HmosVideoDecoder::addRecordingData(const uint8_t *data, size_t size, int64_t timestamp, uint32_t flags) {
    if (muxer_ && isRecording_) {

        if (flags == AVCODEC_BUFFER_FLAGS_SYNC_FRAME) {
            isKeyFrame = true;
        }
        if (!isKeyFrame) {
            return false;
        }


        int32_t n;
        if (size <= INT32_MAX) {
            n = static_cast<int32_t>(size); // 安全
            // 使用 n
        } else {
            // 处理溢出：记录错误、截断、或使用 int64_t 替代
            std::cerr << "size_t value too large for int32_t" << std::endl;
        }


        /* OH_AVMemory *sample = OH_AVMemory_Create(n);
         if (!sample) {
             // 创建失败处理
             printf("创建sample失败");
             return false;
         }
         uint8_t *memoryAddr = OH_AVMemory_GetAddr(sample);
         if (!memoryAddr) {
             // 获取地址失败
             printf("Failed to get memory address\n");
             OH_AVMemory_Destroy(sample);
             return false;
         }

         // 将你的数据拷贝到 OH_AVMemory 中
         memcpy(memoryAddr, data, size);

         // 5. 写入H.264/H.265数据
         OH_AVCodecBufferAttr info = {.pts = frameNumer*100000, // 时间戳
                                      .size = n,                     // 数据大小
                                      .flags = flags};


         LOGI("录制音视频时长, ret=%{public}lld,", timestampR - timestamp);

         // int32_t videoTrackIndex = -1;
         int ret = OH_AVMuxer_WriteSample(muxer_, videoTrackId, sample, info);
        // OH_AVMuxer_WriteSampleBuffer()
      */


        // 6. 创建 OH_AVBuffer，用于承载帧数据
        OH_AVBuffer *sample = OH_AVBuffer_Create(n);
        if (!sample) {
            // 处理创建失败
            return false;
        }
        uint8_t *memoryAddr = OH_AVBuffer_GetAddr(sample);
        if (!memoryAddr) {
            // 获取地址失败
            printf("Failed to get memory address\n");
            OH_AVBuffer_Destroy(sample);
            return false;
        }

        // 7. 将数据拷贝到 buffer 中
        memcpy(memoryAddr, data, n);

        // 8. 设置帧的时间戳和同步帧标志
        OH_AVCodecBufferAttr attr;
        attr.pts = frameNumer * 100000; // 显示时间戳
        attr.size = n;                  // 数据大小
        attr.flags = flags;
        attr.offset = 0;

        // 9. 将属性关联到 buffer
        OH_AVBuffer_SetBufferAttr(sample, &attr);

        // 10. 将 buffer 写入封装器
        int ret = OH_AVMuxer_WriteSampleBuffer(muxer_, videoTrackId, sample);
        /*  if (ret != AV_ERR_OK) {
              // 处理写入失败
          }*/

        // 11. 每一帧写入完毕后，立即释放该 buffer 资源
        OH_AVBuffer_Destroy(sample);


        LOGI("录制添加一帧音视频数据, ret=%{public}d,", ret);
        LOGI("录制添加一帧音视频数据, timestamp=%{public}lld,", frameNumer * 100000);

        frameNumer++;
        /*  // 6. 停止并销毁资源
          OH_AVMuxer_Stop(muxer_);
          OH_AVMuxer_Destroy(muxer_);*/
    } else {
        timestampR = timestamp;
        isKeyFrame = false;
        frameNumer = 0;
    }
    return true;
}

// 码流录制视频停止销毁
bool HmosVideoDecoder::StopRecording() {
    if (muxer_) {
        // 6. 停止并销毁资源
        // 1. 停止封装（最关键！决定文件是否完整）
        int stopRet = OH_AVMuxer_Stop(muxer_);
        // 2. 销毁实例（释放资源）
        int destroyRet = OH_AVMuxer_Destroy(muxer_);
        LOGI("录制结束, stopRet=%{public}d,", stopRet);
        LOGI("录制结束, destroyRet=%{public}d,", destroyRet);
        isRecording_ = false;
    }
    return true;
}


} // extern "C"