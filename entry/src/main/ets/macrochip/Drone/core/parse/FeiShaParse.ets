import { Parse } from './Parse';
import { MessagePacket } from '../message/MessagePacket';
import { ProtocolHeader } from '../protocol/ProtocolHeader';
import { ObjectUtils } from '../../../../utils/ObjectUtils';

/**
 * 解析状态枚举
 */
export enum FeiShaStates {
  STATE_UNINIT,
  STATE_IDLE,
  STATE_START,
  STATE_SUM_LENGTH,
  STATE_MSGID,
  STATE_LENGTH,
  STATE_PAYLOAD,
  STATE_END,
}

/**
 * 飞鲨协议解析类，用于解析无人机通信中的飞鲨协议数据
 */
export class FeiShaParse extends Parse {
  /**
   * 当前解析状态
   */
  private state: FeiShaStates = FeiShaStates.STATE_UNINIT;

  /**
   * 构造函数
   */
  constructor() {
    super();
    // LogUtils.d("飞鲨协议");
  }

  /**
   * 解析单个字节数据
   * @param b 要解析的字节数据
   * @returns 解析后的消息数据包，如果解析成功则返回完整的数据包，否则返回null
   */
  public parse_char(b: number): MessagePacket | null {
    switch (this.state) {
      case FeiShaStates.STATE_UNINIT:
      case FeiShaStates.STATE_IDLE:
        if (b === ProtocolHeader.FEI_SHA_START) {
          this.packet = new MessagePacket();
          // 注意：这里假设Message类有add方法，需要确保Message类中定义了此方法
          // this.packet.message.add(b);
          this.state = FeiShaStates.STATE_START;
        }
        // LogUtils.d("头", b);
        break;
      case FeiShaStates.STATE_START:
        // LogUtils.d("数据总长度", b & 0xFF);
        // this.packet.message.add(b);
        this.state = FeiShaStates.STATE_SUM_LENGTH;
        break;
      case FeiShaStates.STATE_SUM_LENGTH:
        // this.packet.message.add(b);
        this.packet.msgid = b;
        // LogUtils.d("消息ID", this.packet.msgid);
        this.state = FeiShaStates.STATE_MSGID;
        break;
      case FeiShaStates.STATE_MSGID:
        // this.packet.message.add(b);
        this.packet.len = b & 0xFF;
        // LogUtils.d("数据长度", this.packet.len);
        this.state = FeiShaStates.STATE_LENGTH;
        break;
      case FeiShaStates.STATE_LENGTH:
        // this.packet.message.add(b);
        this.packet.payload.addByte(b);
        // LogUtils.d("填充数据", this.packet.payload.size(), ObjectUtils.arrayBufferToHex(new Uint8Array([b])).toUpperCase());
        if (this.packet.payloadIsFilled(2)) {
          this.state = FeiShaStates.STATE_PAYLOAD;
        }
        break;
      case FeiShaStates.STATE_PAYLOAD:
        // this.packet.message.add(b);
        let isCK: boolean = this.packet.generateCK(b);
        if (isCK) {
          // LogUtils.d("校验成功");
          this.state = FeiShaStates.STATE_END;
        } else {
          console.log("校验失败，数据错误");
        }
        // LogUtils.d("校验", b, this.packet.ck?.getCkValue());
        break;
      case FeiShaStates.STATE_END:
        // this.packet.message.add(b);
        // LogUtils.d("结束", b);
        this.state = FeiShaStates.STATE_IDLE;
        if (b === ProtocolHeader.FEI_SHA_END) {
          return this.packet;
        }
        break;
    }
    return null;
  }
}