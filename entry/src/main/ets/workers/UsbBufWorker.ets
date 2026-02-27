import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import NapiBuffer from 'libentry.so';
import { ObjectUtils } from '../utils/ObjectUtils'
import promptAction from '@ohos.promptAction';
import { VideoStreamHandle } from '../connect/stream/VideoStreamHandle';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;



/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessage = (event: MessageEvents) => {

  switch (event.data.type) {
    case 'start_reading':
      break;
    case 'startCUsb':
      startCUsb();
      break
    case 'stopUsb':
stopCUsb()
      break;
  }

};

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param event message data
 */
workerPort.onmessageerror = (event: MessageEvents) => {
};

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param event error message
 */
workerPort.onerror = (event: ErrorEvent) => {
};



let isRunning = false;

function startCUsb():void {
  console.log("newData======————","startCUsb");
  isRunning = true;

  const readData = () => {
    if (!isRunning) {
      return;
    }

    try {
    /*  * @param order  消息顺序。0
      * @param length 消息长度。1
      * @param msgId  消息ID。2*/
      const header:Array<number> = new Array<number>(3);
      // 解析得到数据
      let newData = NapiBuffer.getUsbOneFrame(header);

      if (header[2]==0x03) {
        console.log("newData======————","header="+header);
        console.log("newData======————",ObjectUtils.arrayBufferToHex(newData));
      }

      if (newData?.length>0) {
        workerPort.postMessage({
          type: 'TOAST',
          text:"======"+header[2]+""+newData?.length
        })
      }

      if (header[2]!=0x00) {
        // 发送数据到主线程，包括头部和新的数据
        workerPort.postMessage({
          type: 'usbdata',
          header: header,
          data: newData
        });
      }

      // 继续下一次读取，使用setTimeout避免堆栈溢出，并给其他任务执行机会
      setTimeout(readData, 5);

    } catch (error) {
      console.error('Usb读取错误:', error, error.code);
      isRunning = false;
    }
  };

  // 开始读取循环
  readData();

}

function stopCUsb():void{
  isRunning = false;
}




