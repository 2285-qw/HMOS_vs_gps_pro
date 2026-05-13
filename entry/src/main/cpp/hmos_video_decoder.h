#ifndef HMOS_VIDEO_DECODER_H
#define HMOS_VIDEO_DECODER_H

#include <cstdint>
#include <string>
#include <mutex>
#include <list>
#include <condition_variable>
#include <thread>
#include <functional>
#include <memory>
#include <vector>

// 华为鸿蒙多媒体库
#include <multimedia/player_framework/native_avcodec_videodecoder.h>
#include <multimedia/player_framework/native_avcapability.h>
#include <multimedia/player_framework/native_avcodec_base.h>
#include <multimedia/player_framework/native_avformat.h>
#include <multimedia/player_framework/native_avbuffer.h>
#include <native_window/external_window.h>

//编码相关
#include <multimedia/player_framework/native_avcodec_videoencoder.h>
#include <multimedia/player_framework/native_avmuxer.h>
#include <iostream>

#include <fcntl.h>
#include <sys/stat.h>

// 缓冲区标志
#define AVCODEC_BUFFER_FLAGS_NONE 0
#define AVCODEC_BUFFER_FLAGS_EOS 1
#define AVCODEC_BUFFER_FLAGS_CODEC_CONFIG 2
#define AVCODEC_BUFFER_FLAGS_PARTIAL_FRAME 4
#define AVCODEC_BUFFER_FLAGS_MUXER_DATA 8

// 视频帧结构 - 使用智能内存管理
struct VideoFrame {
    std::vector<uint8_t> data;      // 使用vector自动管理内存
    int32_t width = 0;
    int32_t height = 0;
    int32_t stride = 0;
    int64_t timestamp = 0;
    int32_t format = 0;
    
    VideoFrame() = default;
    
    VideoFrame(int32_t w, int32_t h, int32_t s, int64_t ts, int32_t fmt)
        : width(w), height(h), stride(s), timestamp(ts), format(fmt) {
        // 预分配内存
        size_t ySize = w * h;
        size_t uvSize = ySize / 2;
        size_t totalSize = ySize + uvSize;
        data.resize(totalSize);
    }
    
    // 从原始数据创建
    VideoFrame(const uint8_t* srcData, size_t size, int32_t w, int32_t h, 
               int32_t s, int64_t ts, int32_t fmt)
        : width(w), height(h), stride(s), timestamp(ts), format(fmt) {
        if (srcData && size > 0) {
            data.assign(srcData, srcData + size);
        } else {
            // 如果为空，分配默认大小
            size_t ySize = w * h;
            size_t uvSize = ySize / 2;
            size_t totalSize = ySize + uvSize;
            data.resize(totalSize);
        }
    }
    
    // 深拷贝构造函数
    VideoFrame(const VideoFrame& other)
        : data(other.data)
        , width(other.width)
        , height(other.height)
        , stride(other.stride)
        , timestamp(other.timestamp)
        , format(other.format) {}
    
    // 移动构造函数
    VideoFrame(VideoFrame&& other) noexcept
        : data(std::move(other.data))
        , width(other.width)
        , height(other.height)
        , stride(other.stride)
        , timestamp(other.timestamp)
        , format(other.format) {
        other.width = 0;
        other.height = 0;
        other.stride = 0;
        other.timestamp = 0;
        other.format = 0;
    }
    
    VideoFrame& operator=(VideoFrame&& other) noexcept {
        if (this != &other) {
            data = std::move(other.data);
            width = other.width;
            height = other.height;
            stride = other.stride;
            timestamp = other.timestamp;
            format = other.format;
            
            other.width = 0;
            other.height = 0;
            other.stride = 0;
            other.timestamp = 0;
            other.format = 0;
        }
        return *this;
    }
    
    // 禁用拷贝赋值
    VideoFrame& operator=(const VideoFrame&) = delete;
};

// 使用智能指针管理VideoFrame
using VideoFramePtr = std::shared_ptr<VideoFrame>;
using VideoFrameUniquePtr = std::unique_ptr<VideoFrame>;

// 回调函数类型定义 - 使用智能指针
using OnFrameDecodedCallback = std::function<void(VideoFramePtr frame)>;
using OnErrorCallback = std::function<void(int32_t errorCode)>;
using OnFormatChangedCallback = std::function<void(int32_t width, int32_t height, int32_t format)>;

// 回调任务数据结构（用于异步工作）
struct CallbackTask {
    VideoFramePtr frame;
    int32_t errorCode;
    int32_t width;
    int32_t height;
    int32_t format;
    enum Type {
        FRAME, ERROR, FORMAT_CHANGED
    } type;
};

// 视频解码器类
class HmosVideoDecoder {
public:
    HmosVideoDecoder();
    ~HmosVideoDecoder();
    
    // 初始化解码器
    bool initialize(const std::string& mimeType, int32_t width, int32_t height);
    
    // 设置Surface用于渲染
    bool setSurface(OHNativeWindow* nativeWindow);
    
        // 设置Surface用于渲染
    bool setSurfaceen(OHNativeWindow* nativeWindow);
    
    //码流录制视频
    bool StreamRecording(int32_t fd);
    //码流录制视频添加数据
    bool  addRecordingData(const uint8_t *data, size_t size, int64_t timestamp,uint32_t flags);
    //码流录制视频停止销毁
    bool StopRecording();
    
    // 启动解码器（不设置Surface时使用）
    bool start();
    
    // 设置回调函数
    void setCallbacks(
        OnFrameDecodedCallback frameCallback = nullptr,
        OnErrorCallback errorCallback = nullptr,
        OnFormatChangedCallback formatCallback = nullptr);
    
    // 解码一帧数据（异步）
    bool decodeFrame(const uint8_t* data, size_t size, int64_t timestamp, 
                    uint32_t flags = AVCODEC_BUFFER_FLAGS_NONE);
    
    // 获取解码后的帧（用于内存模式）
    VideoFramePtr getDecodedFrame(int32_t timeoutMs = 0);
    
    // 刷新解码器
    void flush();
    
    // 停止解码器
    void stop();
    
    // 释放解码器
    void release();
    
    // 获取信息
    int32_t getWidth() const { return width_; }
    int32_t getHeight() const { return height_; }
    bool isInitialized() const { return initialized_; }
    bool isStarted() const { return started_; }
    bool isSurfaceMode() const { return surface_ != nullptr; }
    
private:
    // 异步缓冲区数据
    struct PendingInput {
        std::vector<uint8_t> data;    // 使用vector管理数据
        int64_t timestamp;
        uint32_t flags;
        
        PendingInput() = default;
        
        PendingInput(const uint8_t* srcData, size_t size, int64_t ts, uint32_t fl)
            : timestamp(ts), flags(fl) {
            if (srcData && size > 0) {
                data.assign(srcData, srcData + size);
            }
        }
        
        // 移动构造函数
        PendingInput(PendingInput&& other) noexcept
            : data(std::move(other.data))
            , timestamp(other.timestamp)
            , flags(other.flags) {}
        
        // 禁用拷贝
        PendingInput(const PendingInput&) = delete;
        PendingInput& operator=(const PendingInput&) = delete;
    };
    
    // 可用缓冲区
    struct AvailableBuffer {
        uint32_t index;
        OH_AVBuffer* buffer;
    };
    
    // 输出缓冲区信息
    struct OutputBufferInfo {
        uint32_t index;
        OH_AVBuffer* buffer;
    };
    
    // 静态回调函数（适配C接口）
    static void OnError(OH_AVCodec* codec, int32_t errorCode, void* userData);
    static void OnStreamChanged(OH_AVCodec* codec, OH_AVFormat* format, void* userData);
    static void OnInputBufferAvailable(OH_AVCodec* codec, uint32_t index, OH_AVBuffer* buffer, void* userData);
    static void OnOutputBufferAvailable(OH_AVCodec* codec, uint32_t index, OH_AVBuffer* buffer, void* userData);
    
    // 异步处理线程
    void asyncProcessLoop();
    bool processPendingInputs();
    void processAvailableOutput(uint32_t index, OH_AVBuffer* buffer);
    void processOutputBufferToSurface(uint32_t index, OH_AVBuffer* buffer);
    VideoFramePtr createVideoFrameFromBuffer(uint32_t index, OH_AVBuffer* buffer);
    
    // 辅助函数
    bool configureDecoder();
    bool startDecoder();
    bool fillInputBuffer(uint32_t index, OH_AVBuffer* buffer, PendingInput& input);
    void generateTestImage(VideoFramePtr frame);
    
    // 低版本兼容函数
    void handleOutputBufferInCallback(uint32_t index, OH_AVBuffer* buffer);
    
private:
    // 解码器相关
    OH_AVCodec* decoder_;           // 解码器实例
    OH_AVFormat* format_;           // 格式实例
    OHNativeWindow* surface_;       // Surface用于渲染
    
    //录制相关
     OH_AVMuxer *muxer_; //录制实列
    int videoTrackId;//视频录制id
    bool isRecording_;//是否录制
    int64_t timestampR;//视频录制时间戳
    bool isKeyFrame;//录制第一帧是否是关键帧
     int64_t frameNumer;//视频录制帧数
    
    // 回调函数
    OnFrameDecodedCallback frameCallback_;
    OnErrorCallback errorCallback_;
    OnFormatChangedCallback formatChangedCallback_;
    
    // 状态信息
    int32_t width_;
    int32_t height_;
    std::string mimeType_;
    bool initialized_;
    bool started_;
    bool configured_;
    bool useHardware_;
    bool isLowVersion_;            // 是否是低版本（低于20）
    
    // 异步处理相关
    std::mutex inputMutex_;
    std::condition_variable inputCond_;
    std::list<PendingInput> pendingInputs_;          // 等待处理的输入数据
    std::list<AvailableBuffer> availableInputBuffers_; // 可用的输入缓冲区
    
    std::mutex outputMutex_;
    std::condition_variable outputCond_;
    std::list<OutputBufferInfo> availableOutputBuffers_; // 可用的输出缓冲区
    
    std::mutex frameMutex_;
    std::list<VideoFramePtr> decodedFrames_;         // 已解码的帧队列（使用智能指针）
    
    std::thread asyncThread_;                        // 异步处理线程
    bool asyncRunning_;                              // 异步线程运行标志
    
    // 解码统计
    uint64_t framesSubmitted_;
    uint64_t framesDecoded_;
    uint64_t framesRendered_;
    
    // 存储 index 数据的数组
    std::vector<uint32_t> inputBufferIndexes_;  // 输入缓冲区 index
    std::vector<uint32_t> outputBufferIndexes_; // 输出缓冲区 index
    std::mutex indexesMutex_;                   // 保护数组的互斥锁
};

// C接口 - 使用原始指针包装（保持兼容性）
extern "C" {
    // 创建解码器实例
    void* hmos_video_decoder_create();
    
    // 初始化解码器
    bool hmos_video_decoder_initialize(void* decoder, const char* mimeType, 
                                      int32_t width, int32_t height);
    
    // 设置Surface
    bool hmos_video_decoder_set_surface(void* decoder, void* nativeWindow);
    
    // 启动解码器（不设置Surface时使用）
    bool hmos_video_decoder_start(void* decoder);
    
    // 解码一帧数据
    bool hmos_video_decoder_decode_frame(void* decoder, uint8_t* data, 
                                        size_t size, int64_t timestamp);
    
    // 获取解码后的帧（返回原始指针，调用者需要释放）
    void* hmos_video_decoder_get_frame(void* decoder);
    
    // 释放帧
    void hmos_video_decoder_free_frame(void* frame);
    
    // 刷新解码器
    void hmos_video_decoder_flush(void* decoder);
    
    // 释放解码器
    void hmos_video_decoder_release(void* decoder);
    
    // 检查是否支持该格式
    bool hmos_video_decoder_is_supported(const char* mimeType);
}

#endif // HMOS_VIDEO_DECODER_H