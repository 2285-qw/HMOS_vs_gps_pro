//
// Created by Vison on 2025/9/17.
//

#ifndef VISONNDK_USBDATAHEADER_H
#define VISONNDK_USBDATAHEADER_H

#if defined(_MSC_VER)
#   ifndef STRUCT_ATTR
#       define STRUCT_ATTR
#   endif
#else
#   ifndef STRUCT_ATTR
#       define STRUCT_ATTR      __attribute__ ((packed))
#   endif
#endif

#ifdef WIN32
#   pragma pack(1)
#endif

/**
 * @Author:         Sanerly
 * @CreateDate:     2023/12/18 11:45
 * @Description:    USB数据头
 * 头（3byte）	数据序号(2byte)	    长度(2byte)	  功能ID(2byte)	    检验(2byte)	                内容
 * FF5653	    0~65535循环使用	    仅为内容的长度	  01=握手(心跳)       内容检验 byte ^ byte.....	具体数据内容
 */
typedef struct {
    unsigned char header[3];
    unsigned short order;
    unsigned short len;
    unsigned short msgid;
    unsigned short check;
}STRUCT_ATTR UsbDataHeader;


typedef struct {
    unsigned short order;
    unsigned short len;
    unsigned short msgid;
    unsigned short check;
    unsigned char *buf;
} UsbDataHeader_2;


#endif //VISONNDK_USBDATAHEADER_H
