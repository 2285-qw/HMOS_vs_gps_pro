
import { LGControlHyBean } from '../mode/LGControlHyBean';
import { HyExtendBean } from '../mode/HyExtendBean';
import { BluetoothBean } from '../mode/BluetoothBean';
import { LanGuangDataConverter } from '../FunctionalAnalysis/LanGuangDataConverter';
import { BaseControlThread } from './BaseControlThread';
import { PlayInfo } from '../../model/PlayInfo';
import EntryAbility from '../../entryability/EntryAbility';
import { CRC16 } from '../utils/CRC16';
import { ObjectUtils } from '../../utils/ObjectUtils';


export class SendHyControlThread extends BaseControlThread {
    private bean?: LGControlHyBean;
    private aroundValue = 0;
    private pointValue = 0;
    private cancelValue = 0;
    private videoValue = 0;
    private isVisionFollow = false;
    private forbidTakeOff = 0;

    private MotorBeepCrtl = 0;//电机警报声

    private sportMode = 0;
    public skyFly = 0; //冲天功能变高 1 秒后变低
    public farFly = 0;//渐远功能变高 1 秒后变低
    public spiralFly = 0; //螺旋功能变高 1 秒后变低，需要 5 秒内的 0x03 环绕数据
    public magCor = 0; //罗盘校准 	 	 	 变高1秒后变低
    public ptzV = 0;

    private levelCor = 0;//水平校准 变高1秒后变低

    private latitude = 0;
    private longitude = 0;
    private AltitudeGeo = 0;
    private souceType = 0;

    private time = 0;

    constructor() {
        super();
        this.initControl();
        this.initEx();
    }

    private initControl(): void {
        this.bean = new LGControlHyBean();
        this.bean.rocker1 = 128;
        this.bean.rocker2 = 128;
        this.bean.rocker3 = 128;
        this.bean.rocker4 = 128;
        this.bean.leftRightTrim = 0x20;
        this.bean.upDownTrim = 0x20;
        this.bean.ctrlPanel = 0;
        this.bean.display = 0;
    }

    private initEx(): void {
        this.sportMode = 0;
        this.skyFly = 0;
        this.farFly = 0;
        this.spiralFly = 0;
    }

/*    protected doControl(): void {
        this.controlData();
        this.extendData();
    }*/

    private controlData(): void {
        const data = new Uint8Array(17);
        data[0] = 0x68;
        data[1] = 0x01;
        data[2] = 13;


        this.bean!.goHome = this.goHome;
        this.bean!.stop = this.stopValue;
        this.bean!.autoTakeoff = this.toFlyValue;
        this.bean!.autoLand = this.toLandValue;
        this.bean!.lockUnlock = this.lockValue;

        this.bean!.followMe = this.followValue;
        this.bean!.circleFly = this.aroundValue;
        this.bean!.popublicFly = this.pointValue;
        this.bean!.gpsMode = this.cancelValue;
        this.bean!.video = this.videoValue;
        this.bean!.magCor = this.magCor;
        this.bean!.levelCor = this.levelCor;
        this.bean!.ptzV = this.ptzV;

        let rocker4 = this.rotate * 2;
        if (PlayInfo.isHisi()) {
            if (rocker4 < 128 - 60) {
                rocker4 = 128 - 100;
            } else if (rocker4 < 128 - 16) {
                rocker4 = 128 - 60;
            } else if (rocker4 > 128 + 60) {
                rocker4 = 128 + 100;
            } else if (rocker4 > 128 + 16) {
                rocker4 = 128 + 60;
            } else {
                rocker4 = this.rotate * 2;
            }
        } else {
            if (rocker4 < 128 - 60) {
                rocker4 = 128 - 100;
            } else if (rocker4 < 128 - 16) {
                rocker4 = 128 - 60;
            } else if (rocker4 > 128 + 60) {
                rocker4 = 128 + 100;
            } else if (rocker4 > 128 + 16) {
                rocker4 = 128 + 60;
            } else {
                rocker4 = this.rotate * 2;
            }
        }

        // 旋转
        this.bean!.rocker4 = rocker4;
        if (/*TrackThread.isImageFollow || */this.isVisionFollow) {
            this.bean!.ctrlPanel = 1;
            this.bean!.visionFollow = 1;
        } else {
            this.bean!.ctrlPanel = 0;
            this.bean!.visionFollow = 0;
        }

        const newData = LanGuangDataConverter.convertLGControlHyBean(this.bean!);

        // 将newData复制到data数组中，从索引3开始
        for (let i = 0; i < newData.length && i < 13; i++) {
            data[3 + i] = newData[i];
        }

        // 计算校验和
        let checksum = 0;
        for (let i = 1; i < 16; i++) {
            checksum ^= data[i];
        }
        data[16] = checksum;

        if (/*TrackThread.isImageFollow ||*/ this.isVisionFollow) {
            if (PlayInfo.isHisi()) {
                EntryAbility.getInstance().sendUDPCmd(data)
                EntryAbility.getInstance().sendTCPCmd(data)
            } else {
                EntryAbility.getInstance().sendTCPCmd(data)
            }
            this.controlInterval=50

        } else {
            EntryAbility.getInstance().sendUDPCmd(data)
            this.controlInterval=200
        }
        console.log("黑飞控制线程执行")
    }

    private extendData(): void {
        const data = new Uint8Array(12);
        data[0] = 0x68;
        data[1] = 0x0b;
        data[2] = 8;

        const bean = new HyExtendBean();
        bean.MotorBeepCrtl = this.MotorBeepCrtl;
        // 目前没有对应的转换方法，暂时使用空数组
        const newData = new Uint8Array(8);

        // 将newData复制到data数组中，从索引3开始
        for (let i = 0; i < newData.length && i < 8; i++) {
            data[3 + i] = newData[i];
        }

        // 计算校验和
        let checksum = 0;
        for (let i = 1; i < 11; i++) {
            checksum ^= data[i];
        }
        data[11] = checksum;
        EntryAbility.getInstance().sendUDPCmd(data)
    }

    private bluetoothData(): void {
        const data = new Uint8Array(22);
        data[0] = 0x69;
        data[1] = 0x5b;
        data[2] = 0x02;
        data[3] = 0x10;

        const bean = new BluetoothBean();
        // 计算时间戳：当前时间（秒）减去2019年1月1日0点的时间戳
        const currentTime = Math.floor(Date.now() / 1000);
        bean.timestamp = currentTime - 1546300800;
        bean.souceType = this.souceType;
        bean.latitude = this.latitude;
        bean.longitude = this.longitude;
        bean.AltitudeGeo = this.AltitudeGeo;

        // 使用LanGuangDataConverter转换蓝牙数据
        const newData = LanGuangDataConverter.convertBluetoothBean(bean);

        // 将newData复制到data数组中，从索引4开始
        for (let i = 0; i < newData.length && i < 16; i++) {
            data[4 + i] = newData[i];
        }

        // 计算CRC16校验和
        const crcData = data.slice(2, 20);
        const check = CRC16.CRC16_MAXIM(crcData);
        const checks = ObjectUtils.intTo2Bytes(check);
        data[20] = checks[0];
        data[21] = checks[1];
    }

    protected doControl(): void {
        this.controlData();

        if (this.MotorBeepCrtl == 1) {
            this.time = Date.now();
        }
        if (Date.now() - this.time < 2500) {
            this.extendData();
        }

        this.bluetoothData();
    }

    public setFollowValue(followValue: number): void {
        this.followValue = followValue;
    }

    public setAroundValue(aroundValue: number): void {
        this.aroundValue = aroundValue;
    }

    public setPointValue(pointValue: number): void {
        this.pointValue = pointValue;
    }

    public setCancelValue(cancelValue: number): void {
        this.cancelValue = cancelValue;
    }

    public setVideoValue(value: number): void {
        this.videoValue = value;
    }

    public setVisionFollow(visionFollow: boolean): void {
        this.isVisionFollow = visionFollow;
    }

    public setSportMode(sportMode: number): void {
        this.sportMode = sportMode;
    }

    public setMagCor(magCor: number): void {
        this.magCor = magCor;
    }

    public setLevelCor(levelCor: number): void {
        this.levelCor = levelCor;
    }

    public setSkyFly(skyFly: number): void {
        this.skyFly = skyFly;
    }

    public setFarFly(farFly: number): void {
        this.farFly = farFly;
    }

    public setSpiralFly(spiralFly: number): void {
        this.spiralFly = spiralFly;
    }

    public setPtzV(ptzV: number): void {
        this.ptzV = ptzV;
    }

    public getForbidTakeOff(): number {
        return this.forbidTakeOff;
    }

    public setForbidTakeOff(forbidTakeOff: number): void {
        this.forbidTakeOff = forbidTakeOff;
    }

    public setLatitude(latitude: number): void {
        this.latitude = latitude;
    }

    public setLongitude(longitude: number): void {
        this.longitude = longitude;
    }

    public setAltitudeGeo(altitudeGeo: number): void {
        this.AltitudeGeo = altitudeGeo;
    }

    public setSouceType(souceType: number): void {
        this.souceType = souceType;
    }

    public setMotorBeepCrtl(motorBeepCrtl: number): void {
        this.MotorBeepCrtl = motorBeepCrtl;
    }
}