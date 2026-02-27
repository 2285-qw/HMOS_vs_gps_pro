import { BluetoothBean } from "../mode/BluetoothBean";
import { LGControlHyBean } from "../mode/LGControlHyBean";
import { SJHySettingBean } from "../mode/SJHySettingBean";
import { Hy1BBean } from "../mode/Hy1BBean";

export class LanGuangDataConverter {
    /**
     * 将LGControlHyBean转换为符合C语言结构体定义的小段模式Uint8Array
     * 功能字：0x01 定时发送控制数据
     * @param bean LGControlHyBean对象
     * @returns 13字节的Uint8Array
     */
    public static convertLGControlHyBean(bean: LGControlHyBean): Uint8Array {
        // 创建13字节的数组
        const result = new Uint8Array(13);
        
        // 位偏移量
        let bitOffset = 0;
        
        // 1. Roll: 8 bits (左右控制)
        LanGuangDataConverter.setBits(result, bean.rocker1, bitOffset, 8);
        bitOffset += 8;
        
        // 2. Pitch: 8 bits (前后控制)
        LanGuangDataConverter.setBits(result, bean.rocker2, bitOffset, 8);
        bitOffset += 8;
        
        // 3. Thro: 8 bits (油门控制)
        LanGuangDataConverter.setBits(result, bean.rocker3, bitOffset, 8);
        bitOffset += 8;
        
        // 4. Yaw: 8 bits (转向控制)
        LanGuangDataConverter.setBits(result, bean.rocker4, bitOffset, 8);
        bitOffset += 8;
        
        // 5. TrimRoll: 6 bits (左右微调)
        LanGuangDataConverter.setBits(result, bean.leftRightTrim, bitOffset, 6);
        bitOffset += 6;
        
        // 6. TrimPitch: 6 bits (前后微调)
        LanGuangDataConverter.setBits(result, bean.upDownTrim, bitOffset, 6);
        bitOffset += 6;
        
        // 7. FastMode: 1 bit (快档模式)
        LanGuangDataConverter.setBits(result, bean.fastMode, bitOffset, 1);
        bitOffset += 1;
        
        // 8. CFMode: 1 bit (无头模式)
        LanGuangDataConverter.setBits(result, bean.cfMode, bitOffset, 1);
        bitOffset += 1;
        
        // 9. FlipMode: 1 bit (翻滚模式)
        LanGuangDataConverter.setBits(result, bean.flipMode, bitOffset, 1);
        bitOffset += 1;
        
        // 10. GpsMode: 1 bit (取消跟随.环绕.航点模式)
        LanGuangDataConverter.setBits(result, bean.gpsMode, bitOffset, 1);
        bitOffset += 1;
        
        // 11. LevelCor: 1 bit (水平校准)
        LanGuangDataConverter.setBits(result, bean.levelCor, bitOffset, 1);
        bitOffset += 1;
        
        // 12. MagCor: 1 bit (罗盘校准)
        LanGuangDataConverter.setBits(result, bean.magCor, bitOffset, 1);
        bitOffset += 1;
        
        // 13. LockUnlock: 1 bit (加锁解锁)
        LanGuangDataConverter.setBits(result, bean.lockUnlock, bitOffset, 1);
        bitOffset += 1;
        
        // 14. AutoTakeoff: 1 bit (一键起飞)
        LanGuangDataConverter.setBits(result, bean.autoTakeoff, bitOffset, 1);
        bitOffset += 1;
        
        // 15. AutoLand: 1 bit (一键降落)
        LanGuangDataConverter.setBits(result, bean.autoLand, bitOffset, 1);
        bitOffset += 1;
        
        // 16. GoHome: 1 bit (一键返航)
        LanGuangDataConverter.setBits(result, bean.goHome, bitOffset, 1);
        bitOffset += 1;
        
        // 17. Stop: 1 bit (一键急停)
        LanGuangDataConverter.setBits(result, bean.stop, bitOffset, 1);
        bitOffset += 1;
        
        // 18. FollowMe: 1 bit (启动跟随飞行)
        LanGuangDataConverter.setBits(result, bean.followMe, bitOffset, 1);
        bitOffset += 1;
        
        // 19. CircleFly: 1 bit (启动环绕飞行)
        LanGuangDataConverter.setBits(result, bean.circleFly, bitOffset, 1);
        bitOffset += 1;
        
        // 20. PointFly: 1 bit (启动航点飞行)
        LanGuangDataConverter.setBits(result, bean.popublicFly, bitOffset, 1);
        bitOffset += 1;
        
        // 21. Photo: 1 bit (拍照状态)
        LanGuangDataConverter.setBits(result, bean.photo, bitOffset, 1);
        bitOffset += 1;
        
        // 22. Video: 1 bit (摄像状态)
        LanGuangDataConverter.setBits(result, bean.video, bitOffset, 1);
        bitOffset += 1;
        
        // 23. PTZ_H: 2 bits (云台平移)
        LanGuangDataConverter.setBits(result, bean.ptzH, bitOffset, 2);
        bitOffset += 2;
        
        // 24. PTZ_V: 2 bits (云台俯仰)
        LanGuangDataConverter.setBits(result, bean.ptzV, bitOffset, 2);
        bitOffset += 2;
        
        // 25. CtrlPanel: 1 bit (控制盘开关指示)
        LanGuangDataConverter.setBits(result, bean.ctrlPanel, bitOffset, 1);
        bitOffset += 1;
        
        // 26. display: 1 bit (参数显示屏开关)
        LanGuangDataConverter.setBits(result, bean.display, bitOffset, 1);
        bitOffset += 1;
        
        // 27. OpticalFlowOn: 1 bit (打开室内光流模式)
        LanGuangDataConverter.setBits(result, bean.opticalFlowOn, bitOffset, 1);
        bitOffset += 1;
        
        // 28. VisionFollow: 1 bit (视觉跟随)
        LanGuangDataConverter.setBits(result, bean.visionFollow, bitOffset, 1);
        bitOffset += 1;
        
        // 29. Dis_valid: 1 bit (跟随数据有效)
        LanGuangDataConverter.setBits(result, bean.disValid, bitOffset, 1);
        bitOffset += 1;
        
        // 30. Distance: 12 bits (与跟随人的距离)
        LanGuangDataConverter.setBits(result, bean.distance, bitOffset, 12);
        bitOffset += 12;
        
        // 31. Box_x: 12 bits (跟随框中心x坐标)
        LanGuangDataConverter.setBits(result, bean.boxX, bitOffset, 12);
        bitOffset += 12;
        
        // 32. Box_y: 11 bits (跟随框中心y坐标)
        LanGuangDataConverter.setBits(result, bean.boxY, bitOffset, 11);
        bitOffset += 11;
        
        return result;
    }

    /**
     * 将数据按位填充到Uint8Array中（小段模式）
     * @param buffer 目标Uint8Array
     * @param value 要填充的值
     * @param bitOffset 起始位偏移
     * @param bitLength 位长度
     */
    private static setBits(buffer: Uint8Array, value: number, bitOffset: number, bitLength: number): void {
        let byteIndex = bitOffset / 8;
        let bitPosition = bitOffset % 8;
        
        // 确保值在指定位数范围内
        const mask = (1 << bitLength) - 1;
        value = value & mask;
        
        // 逐位填充数据
        for (let i = 0; i < bitLength; i++) {
            const bit = (value >> i) & 1;
            const currentByteIndex = Math.floor((bitOffset + i) / 8);
            const currentBitPosition = (bitOffset + i) % 8;
            
            if (bit === 1) {
                buffer[currentByteIndex] |= (1 << currentBitPosition);
            } else {
                buffer[currentByteIndex] &= ~(1 << currentBitPosition);
            }
        }
    }

    /**
     * 将Uint8Array转换为十六进制字符串，用于调试
     * @param buffer Uint8Array
     * @returns 十六进制字符串
     */
    public static uint8ArrayToHex(buffer: Uint8Array): string {
        return Array.from(buffer).map(byte => byte.toString(16).padStart(2, '0')).join(' ');
    }

    /**
     * 将BluetoothBean转换为符合C语言结构体定义的小段模式Uint8Array
     * 功能字：0x1a 请求交换基本信息
     * @param bean BluetoothBean对象
     * @returns 10字节的Uint8Array
     */
    public static convertBluetoothBean(bean: BluetoothBean): Uint8Array {
        // 创建10字节的数组
        const result = new Uint8Array(10);
        const dataView = new DataView(result.buffer);
        
        // 1. timestamp: 4 bytes (uint32_t) - 小端模式
        dataView.setUint32(0, bean.timestamp, true);
        
        // 2. latitude: 4 bytes (int32_t) - 小端模式
        dataView.setInt32(4, bean.latitude, true);
        
        // 3. longitude: 4 bytes (int32_t) - 小端模式，只取前2字节（因为总长度是10字节）
        dataView.setUint16(8, bean.longitude & 0xFFFF, true);
        
        // 注意：根据union定义，RequestExchangeDataBytes是10字节，所以只取前10字节
        // 实际结构体字段总和是16字节，这里按照定义只取10字节
        return result;
    }

    /**
     * 将SJHySettingBean转换为符合C语言结构体定义的小段模式Uint8Array
     * 功能字：0x1a 请求交换基本信息
     * @param bean SJHySettingBean对象
     * @returns 6字节的Uint8Array
     */
    public static convertSJHySettingBean(bean: SJHySettingBean): Uint8Array {
        // 创建6字节的数组（48bit）
        const result = new Uint8Array(6);
        
        // 位偏移量
        let bitOffset = 0;
        
        // 1. UseMagDec: 8 bits (是否使用 APP 的磁偏角)
        LanGuangDataConverter.setBits(result, bean.UseMagDec, bitOffset, 8);
        bitOffset += 8;
        
        // 2. MagDec: 8 bits (当地磁偏角)
        LanGuangDataConverter.setBits(result, bean.MagDec, bitOffset, 8);
        bitOffset += 8;
        
        // 3. Limhigh: 10 bits (最大限飞高度 0~1023 米)
        LanGuangDataConverter.setBits(result, bean.Limhigh, bitOffset, 10);
        bitOffset += 10;
        
        // 4. Limdistance: 12 bits (最大限飞距离 0~4096 米)
        LanGuangDataConverter.setBits(result, bean.Limdistance, bitOffset, 12);
        bitOffset += 12;
        
        // 5. Gohomehigh: 10 bits (返航高度 0~限距高度)
        LanGuangDataConverter.setBits(result, bean.Gohomehigh, bitOffset, 10);
        bitOffset += 10;
        
        return result;
    }

    /**
     * 将Hy1BBean转换为符合C语言结构体定义的小段模式Uint8Array
     * 功能字：0x1b 请求交换基本信息
     * @param bean Hy1BBean对象
     * @returns 10字节的Uint8Array
     */
    public static convertHy1BBean(bean: Hy1BBean): Uint8Array {
        // 创建10字节的数组（80bit）
        const result = new Uint8Array(10);
        
        // 位偏移量
        let bitOffset = 0;
        
        // 1. UseMagDec: 8 bits (是否使用 APP 的磁偏角)
        LanGuangDataConverter.setBits(result, bean.UseMagDec, bitOffset, 8);
        bitOffset += 8;
        
        // 2. MagDec: 8 bits (当地磁偏角)
        LanGuangDataConverter.setBits(result, bean.MagDec, bitOffset, 8);
        bitOffset += 8;
        
        // 3. Limhigh: 16 bits (最大限飞高度 0~1023 米)
        LanGuangDataConverter.setBits(result, bean.Limhigh, bitOffset, 16);
        bitOffset += 16;
        
        // 4. Limdistance: 16 bits (最大限飞距离 0~4096 米)
        LanGuangDataConverter.setBits(result, bean.Limdistance, bitOffset, 16);
        bitOffset += 16;
        
        // 5. Gohomehigh: 16 bits (返航高度 0~限距高度)
        LanGuangDataConverter.setBits(result, bean.Gohomehigh, bitOffset, 16);
        bitOffset += 16;
        
        // 6. Gohomehigh2: 16 bits (返航高度 0~限距高度)
        LanGuangDataConverter.setBits(result, bean.Gohomehigh2, bitOffset, 16);
        bitOffset += 16;
        
        return result;
    }
}