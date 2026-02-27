/*

import videoDecoder from 'libentry.so';

export class VideoDecoderManager {
  private decoder: any = null;
  private isInitialized: boolean = false;
  private width: number = 0;
  private height: number = 0;
  private frameQueue: Array<videoDecoder.VideoFrame> = [];
  private isProcessing: boolean = false;

  */
/**
   * 创建解码器实例
   *//*

  async createDecoder(mimeType: string, width: number, height: number): Promise<boolean> {
    try {
      // 检查解码器是否支持
      if (!videoDecoder.isDecoderSupported(mimeType)) {
        console.error(`Decoder not supported for MIME type: ${mimeType}`);
        return false;
      }

      // 创建解码器
      this.decoder = videoDecoder.CreateDecoder(mimeType, width, height);

      if (!this.decoder) {
        console.error('Failed to create decoder');
        return false;
      }

      this.width = width;
      this.height = height;
      this.isInitialized = true;

      console.log(`Video decoder created successfully: ${mimeType} ${width}x${height}`);
      return true;
    } catch (error) {
      console.error('Error creating decoder:', error);
      return false;
    }
  }

  */
/**
   * 解码单个视频帧
   *//*

  async decodeFrame(frameData: Uint8Array, timestamp: number): Promise<boolean> {
    if (!this.isInitialized || !this.decoder) {
      console.error('Decoder not initialized');
      return false;
    }

    try {
      const result = videoDecoder.decodeFrame(this.decoder, frameData, timestamp);

      if (!result) {
        console.warn('Failed to decode frame');
        return false;
      }

      // 获取解码后的帧
      const decodedFrame = this.getDecodedFrame();
      if (decodedFrame) {
        this.frameQueue.push(decodedFrame);
        return true;
      }

      return false;
    } catch (error) {
      console.error('Error decoding frame:', error);
      return false;
    }
  }

  */
/**
   * 获取解码后的帧
   *//*

  getDecodedFrame(): videoDecoder.VideoFrame | null {
    if (!this.isInitialized || !this.decoder) {
      return null;
    }

    try {
      return videoDecoder.getDecodedFrame(this.decoder);
    } catch (error) {
      console.error('Error getting decoded frame:', error);
      return null;
    }
  }

  */
/**
   * 批量解码视频帧
   *//*

  async decodeFrames(frames: Array<{ data: Uint8Array; timestamp: number }>): Promise<number> {
    if (!this.isInitialized) {
      console.error('Decoder not initialized');
      return 0;
    }

    let successCount = 0;

    for (const frame of frames) {
      if (await this.decodeFrame(frame.data, frame.timestamp)) {
        successCount++;
      }
    }

    return successCount;
  }

  */
/**
   * 清空帧队列
   *//*

  clearFrameQueue(): void {
    this.frameQueue = [];
  }

  */
/**
   * 获取帧队列
   *//*

  getFrameQueue(): videoDecoder.VideoFrame[] {
    return [...this.frameQueue];
  }

  */
/**
   * 获取一帧
   *//*

  popFrame(): videoDecoder.VideoFrame | null {
    return this.frameQueue.shift() || null;
  }

  */
/**
   * 释放解码器资源
   *//*

  release(): void {
    if (this.decoder) {
      videoDecoder.releaseDecoder(this.decoder);
      this.decoder = null;
      this.isInitialized = false;
      this.clearFrameQueue();
      console.log('Video decoder released');
    }
  }

  */
/**
   * 获取支持的编解码器列表
   *//*

  static getSupportedCodecs(): string[] {
    try {
      return videoDecoder.getSupportedCodecs();
    } catch (error) {
      console.error('Error getting supported codecs:', error);
      return [];
    }
  }

  */
/**
   * 检查编解码器是否支持
   *//*

  static isCodecSupported(mimeType: string): boolean {
    try {
      return videoDecoder.isDecoderSupported(mimeType);
    } catch (error) {
      console.error('Error checking codec support:', error);
      return false;
    }
  }

  */
/**
   * 将NV21数据转换为RGBA数据
   *//*

  static convertNV21ToRGBA(nv21Data: Uint8Array, width: number, height: number): ImageData | null {
    try {
      // 创建Canvas用于图像处理
      const canvas = new OffscreenCanvas(width, height);
      const ctx = canvas.getContext('2d');

      if (!ctx) {
        console.error('Failed to get canvas context');
        return null;
      }

      // 创建ImageData
      const imageData = ctx.createImageData(width, height);

      // 计算NV21数据大小
      const ySize = width * height;
      const uvSize = ySize / 2;

      // NV21到RGBA转换
      for (let y = 0; y < height; y++) {
        for (let x = 0; x < width; x++) {
          const yIndex = y * width + x;
          const uvIndex = Math.floor(y / 2) * width + (x & ~1);

          const yValue = nv21Data[yIndex];
          const uValue = nv21Data[ySize + uvIndex] - 128;
          const vValue = nv21Data[ySize + uvIndex + 1] - 128;

          // YUV到RGB转换
          let r = yValue + 1.402 * vValue;
          let g = yValue - 0.344136 * uValue - 0.714136 * vValue;
          let b = yValue + 1.772 * uValue;

          // 裁剪到0-255范围
          r = Math.max(0, Math.min(255, r));
          g = Math.max(0, Math.min(255, g));
          b = Math.max(0, Math.min(255, b));

          const rgbaIndex = (y * width + x) * 4;
          imageData.data[rgbaIndex] = r;
          imageData.data[rgbaIndex + 1] = g;
          imageData.data[rgbaIndex + 2] = b;
          imageData.data[rgbaIndex + 3] = 255; // Alpha通道
        }
      }

      return imageData;
    } catch (error) {
      console.error('Error converting NV21 to RGBA:', error);
      return null;
    }
  }
}*/
