import { Parse } from './Parse';
import { MessagePacket } from '../message/MessagePacket';
import { ProtocolHeader } from '../protocol/ProtocolHeader';

import { ObjectUtils } from '../../../../utils/ObjectUtils';

/**
 * 解析状态枚举
 */
export enum LanGuangStates {
  STATE_UNINIT,
  STATE_IDLE,
  STATE_HEADER,
  STATE_LENGTH,
  STATE_MSGID,
  STATE_PAYLOAD,
}

/**
 * 蓝光/黑飞协议解析类，用于解析无人机通信中的蓝光/黑飞协议数据
 */
export class LanGuangParse extends Parse {
  /**
   * 当前解析状态
   */
  private state: LanGuangStates = LanGuangStates.STATE_UNINIT;

  /**
   * 构造函数
   */
  constructor() {
    super();
    // LogUtils.d("蓝光/黑飞协议");
  }

  /**
   * 解析单个字节数据
   * @param b 要解析的字节数据
   * @returns 解析后的消息数据包，如果解析成功则返回完整的数据包，否则返回null
   */
  public parse_char(b: number): MessagePacket | null {
    switch (this.state) {
      case LanGuangStates.STATE_UNINIT:
      case LanGuangStates.STATE_IDLE:
        if (b === ProtocolHeader.LAN_GUANG) {
          this.packet = new MessagePacket();
          // 注意：这里假设Message类有add方法，需要确保Message类中定义了此方法
          // this.packet.message.add(b);
          this.state = LanGuangStates.STATE_HEADER;
        }
        // LogUtils.d("头", b);
        break;
      case LanGuangStates.STATE_HEADER:
        // this.packet.message.add(b);
        this.packet.msgid = b & 0xFF;
        this.state = LanGuangStates.STATE_MSGID;
        // LogUtils.d("消息ID", this.packet.msgid);
        break;
      case LanGuangStates.STATE_MSGID:
        // this.packet.message.add(b);
        this.packet.len = b & 0xFF;
        // LogUtils.d("长度", this.packet.len);
        this.state = LanGuangStates.STATE_LENGTH;
        break;
      case LanGuangStates.STATE_LENGTH:
        // LogUtils.d("填充数据", this.packet.payload.size(), ObjectUtils.arrayBufferToHex(new Uint8Array([b])).toUpperCase());
        // this.packet.message.add(b);
        this.packet.payload.addByte(b);
        if (this.packet.payloadIsFilled(0)) {
          this.state = LanGuangStates.STATE_PAYLOAD;
        }
        break;
      case LanGuangStates.STATE_PAYLOAD:
        // this.packet.message.add(b);
        this.state = LanGuangStates.STATE_IDLE;
        let isCK: boolean = this.packet.generateCK(b);
        if (isCK) {
          // LogUtils.d("校验成功");
          return this.packet;
        } else {
         console.log("校验失败，数据错误");
        }
        // LogUtils.d("校验", b, this.packet.ck?.getCkValue());
        break;
    }
    return null;
  }
}