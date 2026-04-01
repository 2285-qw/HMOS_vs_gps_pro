import { PlayInfo } from "../model/PlayInfo";
import { UsbWriteCommands } from "../connect/usb/UsbWriteCommands";
import EntryAbility from "../entryability/EntryAbility";

export class FunctionHelper{
  /**
   * 翻转画面
   */
  public static switchRev(): void {
    const isMirror: boolean = !PlayInfo.mirror;
    if (isMirror) {
      EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x02]));
    } else {
      EntryAbility.getInstance().sendUDPCmd(new Uint8Array([0x01]));
    }
    PlayInfo.mirror = isMirror;
  }
}