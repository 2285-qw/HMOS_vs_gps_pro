import { Content } from "@kit.ArkUI";
import { Context } from "@ohos.arkui.UIContext";
import { BusinessError } from "@kit.BasicServicesKit";
import { util } from "@kit.ArkTS";
import { emitter } from '@kit.BasicServicesKit';
import { map, mapCommon } from '@kit.MapKit';

import { media } from '@kit.MediaKit';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
export class ObjectUtils {
  //ArrayBuffer转成16进制数据
  public static arrayBufferToHex(buffer: ArrayBuffer): string {
    return Array.from(new Uint8Array(buffer))
      .map(byte => byte.toString(16).padStart(2, '0')) // 每个字节转为两位十六进制
      .join(' '); // 用空格分隔
  }

  /**
   * 将byte[2]转换成short
   * 小端在前，大端在后
   *
   * @param b
   * @return
   */
  public static byte2ToShort(buffer: ArrayBuffer): number {
    return (((buffer[0] & 0xff) << 8) | (buffer[1] & 0xff));
  }


  /**
   * 将byte[2]转换成short
   * * 大端在前，小端在后
   *
   * @param b
   * @return
   */
  public static byte2ToShort2(buffer: ArrayBuffer): number {
    return (((buffer[1] & 0xff) << 8) | (buffer[0] & 0xff));
  }

  /**
   * int 转 2个字节byte
   * 小端在前大端在后
   *
   * @param val
   * @return
   */
  public static  intTo2Bytes( num:number):Uint8Array {
    // 创建长度为2的Uint8Array
    let  arr = new Uint8Array(2);

    // 大端序（高位在前）
   /* arr[0] = (num >> 8) & 0xFF;  // 高8位
    arr[1] = num & 0xFF;         // 低8位*/

    // 或者小端序（低位在前）
     arr[0] = num & 0xFF;        // 低8位
     arr[1] = (num >> 8) & 0xFF; // 高8位

    return arr;
}

//把Uint8Array转成string
  public static  uint8ArrayToString(input: Uint8Array): string {
    // 创建解码器，指定 UTF-8 编码
    let textDecoder = util.TextDecoder.create('utf-8', {
      fatal: false,    // 忽略解码错误
      ignoreBOM: true  // 忽略字节顺序标记
    });
    // 执行转换
    return textDecoder.decodeToString(input, { stream: false });
  }





  // 十六进制颜色转颜色矩阵工具函数（示例）
  public static  hexToColorMatrix(hex: string): number[] {
    // 验证格式: 支持 #RRGGBB 或 #AARRGGBB
    if (!/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(hex)) {
      throw new Error('Invalid hex color format');
    }

    let cleanedHex = hex.replace('#', '');
    if (cleanedHex.length === 6) {
      cleanedHex = 'FF' + cleanedHex; // 补全透明度通道
    }

    // 解析RGBA值并归一化到 [0, 1]
    const r = parseInt(cleanedHex.substr(2, 2), 16) / 255;
    const g = parseInt(cleanedHex.substr(4, 2), 16) / 255;
    const b = parseInt(cleanedHex.substr(6, 2), 16) / 255;
    const a = parseInt(cleanedHex.substr(0, 2), 16) / 255;

    // 构建颜色矩阵（忽略原图颜色，直接覆盖为目标色）
    return [
      0, 0, 0, 0, r, // 红色通道
      0, 0, 0, 0, g, // 绿色通道
      0, 0, 0, 0, b, // 蓝色通道
      0, 0, 0, a, 0  // 透明度通道（保留原始透明度混合）
    ];


  }

  private static  sendNotice(id: number, data?: Uint8Array) {
    // 1. 创建事件对象
    const innerEvent: emitter.InnerEvent = {
      eventId: id, // 事件ID，需与接收方保持一致
      priority: emitter.EventPriority.HIGH  // 优先级控制
    };

    // 2. 创建要发送的数据
    const eventData: emitter.EventData = {
      data: { data: data }
    };

    // 3. 发送事件
    emitter.emit(innerEvent, eventData);
    console.log("事件发送成功");
  }




// 将 WGS84 转换为 GCJ02
public static  wgs84ToGcj84(wgsLat: number, wgsLng: number): mapCommon.LatLng {
  const wgsPos: mapCommon.LatLng = { latitude: wgsLat, longitude: wgsLng };
  return map.convertCoordinateSync(
    mapCommon.CoordinateType.WGS84,
    mapCommon.CoordinateType.GCJ02,
    wgsPos
  );
}




/*
  async generateThumbnail(videoUri: string, thumbPath: string): Promise<void> {
    let imageGenerator: media.AVImageGenerator | null = null;
    let file: fs.File | null = null;
    try {
      // 1. 创建 AVImageGenerator
      imageGenerator = await media.createAVImageGenerator();

      // 2. 打开视频文件
      const videoPath = videoUri.replace('file://', '');
      file = fs.openSync(videoPath, fs.OpenMode.READ_ONLY);
      const fileStats = fs.statSync(videoPath);
      // fdSrc 赋值（直接使用对象字面量，避免类型依赖）
      imageGenerator.fdSrc = {
        fd: file.fd,
        offset: 0,
        length: fileStats.size
      };
      // 3. 提取第一帧（API 12 需要三个参数）
      //    timeUs: 0（微秒）
      //    options: AV_IMAGE_QUERY_NEXT_SYNC （获取 >= timeUs 的最近一帧）
      //    param: 输出尺寸和格式
      const pixelMap = await imageGenerator.fetchFrameByTime(
        0,
        media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC,
        { width: 400, height: 400 }   // 输出缩略图尺寸，可自行调整
      );

      if (pixelMap) {
        // 4. 编码并保存为 JPEG
        const imagePacker = image.createImagePacker();
        const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 80 };
        const data = await imagePacker.packToData(pixelMap, packOpts);
        const thumbFile = fs.openSync(thumbPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
        fs.writeSync(thumbFile.fd, data);
        fs.closeSync(thumbFile);
        imagePacker.release();
        pixelMap.release();
      }

      // 5. 更新 Map，触发界面刷新
      this.thumbnailMap.set(videoUri, thumbPath);
    } catch (err) {
      console.error(`生成缩略图失败 ${videoUri}: ${err}`);
    } finally {
      // 释放资源
      if (imageGenerator) {
        imageGenerator.release();
      }
      if (file) {
        fs.closeSync(file);
      }
    }
  }*/



}
