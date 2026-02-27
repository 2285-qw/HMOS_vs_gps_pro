import { Protocol } from '../protocol/Protocol';
import { Parse } from './Parse';
import { VisonParse } from './VisonParse';
import { LiHuangParse } from './LiHuangParse';
import { LanGuangParse } from './LanGuangParse';
import { FeiShaParse } from './FeiShaParse';
import { BiteParse } from './BiteParse';

/**
 * 解析工具类，用于根据协议类型创建对应的解析器实例
 */
export class ParseUtils {
  /**
   * 私有构造函数，防止实例化
   */
  private constructor() {
    // 防止实例化
  }

  /**
   * 根据协议类型实例化对应的解析器
   * 
   * @param protocol 协议类型
   * @returns 解析器实例，如果协议类型为NONE则返回null
   */
  public static newInstance(protocol: Protocol): Parse | null {
    // LogUtils.d(JSON.stringify(protocol));
    switch (protocol) {
      case Protocol.VISON:
        return new VisonParse();
      case Protocol.LI_HUANG:
        return new LiHuangParse();
      case Protocol.LAN_GUANG:
        return new LanGuangParse();
      case Protocol.FEI_SHA:
        return new FeiShaParse();
      case Protocol.BI_TE:
        return new BiteParse();
      case Protocol.NONE:
        return null;
      default:
        return null;
    }
  }
}