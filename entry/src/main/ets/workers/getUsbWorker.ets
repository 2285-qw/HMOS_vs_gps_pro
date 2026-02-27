// worker.ets
import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { VideoStreamHandle } from '../connect/stream/VideoStreamHandle';
import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';
import NapiBuffer from 'libentry.so';
import taskpool from '@ohos.taskpool';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
let isReading = false;
let fileDescriptor: number = -1;


// 注册onmessage回调，当Worker线程收到来自其宿主线程通过postMessage接口发送的消息时被调用，在Worker线程执行
workerPort.onmessage = (e: MessageEvents) => {
  switch (e.data.type) {
    case 'start_reading':

      fileDescriptor = e.data.fd;
      startReading(e.data.bufferSize);
      break;

    case 'stop_reading':
      stopReading();
      break;
  }

}


// 开始读取数据
function startReading(bufferSize: number): void {
  if (isReading || fileDescriptor <= 0) {
    return;
  }

  isReading = true;

  // 异步读取循环
  const readLoop = () => {
    if (!isReading) {
      return;
    }

    try {
      const buffer = new ArrayBuffer(bufferSize);
      const bytesRead = fs.readSync(fileDescriptor, buffer, {
        offset: 0,
        length: bufferSize
      });

      if (bytesRead > 0) {
        const data = new Uint8Array(buffer, 0, bytesRead);
        NapiBuffer.addUsbStream(data,bytesRead)
        // 发送回主线程
        //workerPort.postMessage(data);
      /*  workerPort.postMessage({
          type: 'TOAST',
          text:'startReading读取到数据'
        })*/
      }
      console.error('Worker读取usb数据中' );
      // 继续读取
      setTimeout(readLoop, 5);

    } catch (error) {
      workerPort.postMessage({
        type: 'TOAST',
        text:'Worker读取错误'+ error
      })

      console.error('Worker读取错误:', error);
      isReading = false;
    }
  };

  readLoop();
}

// 停止读取
function stopReading(): void {
  isReading = false;
}

// 注册onmessageerror回调，当Worker对象接收到一条无法被序列化的消息时被调用，在Worker线程执行
workerPort.onmessageerror = () => {
  console.error('workerPort onmessageerror');
}

// 注册onerror回调，捕获Worker在执行过程中发生的异常，在Worker线程执行
workerPort.onerror = (err: ErrorEvent) => {
  console.error('workerPort onerror err is: ', err.message);
}

function delay(arg0: number) {
  throw new Error('Function not implemented.');
}
