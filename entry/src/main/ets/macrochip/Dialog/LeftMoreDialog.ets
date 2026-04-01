import { SlideUnLockView } from "../components/SlideUnLockView";
import { MoreBean } from "../More/MoreBean";
import { MoreParams } from "./DialogDataType/MoreParams";
import { MoreType } from "../More/MoreType";
import { Params, Type } from "./DialogDataType/Params";
import { ObjectUtils } from "../../utils/ObjectUtils";


@Builder
export function buildLeftMore(params: MoreParams) {
  Column() {
    List() {
      ForEach(params.arrMoreBean, (item: MoreBean,index: number) => {
        ListItem() {
          Column(){
            Image(item.getIcon()).width(30).height(30).colorFilter(item.isSelected()?ObjectUtils.hexToColorMatrix('#ff008ff4'):undefined)
            Text(item.getText())
              .fontSize(12)
              .fontColor('#faffffff')
              .margin({top:4})
          }.margin(5).onClick(()=>{
           // onItemClick(item.getType());
            if (params.onItemClick) {
              params.onItemClick(index);
            }
          })
        }
      },(item: MoreBean) => item.id)
    }
    .lanes(6) // 设置每行最大列数
    .alignListItem(ListItemAlign.Center) // 居中对齐


  }.borderRadius(15).background('#66393636').outlineRadius(20).padding({left:30,right:30,top:20,bottom:20}).width(320)
}