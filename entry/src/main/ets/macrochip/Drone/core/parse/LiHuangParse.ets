import { Parse } from './Parse';
import { MessagePacket } from '../message/MessagePacket';
import { ProtocolHeader } from '../protocol/ProtocolHeader';

import { ObjectUtils } from '../../../../utils/ObjectUtils';

/**
 * 解析状态枚举
 */
export enum LiHuangStates {
  STATE_UNINIT,
  STATE_IDLE,
  STATE_HEADER_1,
  STATE_HEADER_2,
  STATE_LENGTH,
  STATE_MSGID,
  STATE_PAYLOAD,
}

/**
 * 立煌协议解析类，用于解析无人机通信中的立煌协议数据
 */
export class LiHuangParse extends Parse {
  /**
   * 当前解析状态
   */
  private state: LiHuangStates = LiHuangStates.STATE_UNINIT;

  /**
   * 构造函数
   */
  constructor() {
    super();
    // LogUtils.d("立煌协议");
  }

  /**
   * 解析单个字节数据
   * @param b 要解析的字节数据
   * @returns 解析后的消息数据包，如果解析成功则返回完整的数据包，否则返回null
   */
  public parse_char(b: number): MessagePacket | null {
    switch (this.state) {
      case LiHuangStates.STATE_UNINIT:
      case LiHuangStates.STATE_IDLE:
        if (b === ProtocolHeader.LI_HUANG_0) {
          this.packet = new MessagePacket();
          // 注意：这里假设Message类有add方法，需要确保Message类中定义了此方法
          // this.packet.message.add(b);
          this.state = LiHuangStates.STATE_HEADER_1;
        }
        // LogUtils.d("头1", b);
        break;
      case LiHuangStates.STATE_HEADER_1:
        if (b === ProtocolHeader.LI_HUANG_1) {
          // this.packet.message.add(b);
          this.state = LiHuangStates.STATE_HEADER_2;
        }
        // LogUtils.d("头2", b);
        break;
      case LiHuangStates.STATE_HEADER_2:
        // this.packet.message.add(b);
        this.packet.len = b & 0xFF;
        // LogUtils.d("长度", this.packet.len);
        this.state = LiHuangStates.STATE_LENGTH;
        break;
      case LiHuangStates.STATE_LENGTH:
        // this.packet.message.add(b);
        this.packet.msgid = b;
        this.state = LiHuangStates.STATE_MSGID;
        // LogUtils.d("消息ID", this.packet.msgid);
        break;
      case LiHuangStates.STATE_MSGID:
        // this.packet.message.add(b);
        this.packet.payload.addByte(b);
        // LogUtils.d("填充数据", this.packet.payload.size(), ObjectUtils.arrayBufferToHex(new Uint8Array([b])).toUpperCase());
        if (this.packet.payloadIsFilled(1)) {
          this.state = LiHuangStates.STATE_PAYLOAD;
        }
        break;
      case LiHuangStates.STATE_PAYLOAD:
        // this.packet.message.add(b);
        this.state = LiHuangStates.STATE_IDLE;
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