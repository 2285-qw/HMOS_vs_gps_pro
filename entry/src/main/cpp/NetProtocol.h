#ifndef _NET_PROTOCOL_H_
#define _NET_PROTOCOL_H_

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
//char占1字节，short占 2 字节，int 、float、long 都占 4 字节，double 占8 字节
typedef struct tagDevFrameHead 
{
    unsigned char       FrmHd[4];     //0x00, 0x00, 0x01, 0xax
    //FrmHd[4]第四个字节表示帧类型，0xa1表示I帧，0xa2表示B帧，0xa0表示P帧，0xa4表示音频帧，0xa5表示JPEG。
    //前三个字节目前默认填充0x00, 0x00, 0x01,
    unsigned char       chan;         //通道号
    unsigned char       Vmsflag;      //当前帧视频主次码流标示  0:主 1:次
    unsigned char       AVOption;     //代表当前通道码流组成，并非指当前帧是什么帧
    //AVOption代表码流成分，00视频、01 音频、10 混合，可根据实际需求扩展及调整
    unsigned char       VideoFormat;  //视频编码格式 ....参照VENCFormat_e
    unsigned char       AudioFormat;  //音频编码格式 ....参照AudioCodecFormat_e
    unsigned char       restart_flag;
    //restart_flag是用来告知解码端，视频属性(如分辨率 b帧等)发生了变化
    unsigned char       frmnum;       //帧号
    unsigned char       Framerate;    //帧率  2010.08.04 add
    unsigned int		Bitrate;      //码率  单位kbps 2010.08.04 add
    int                 framelen;     //frame length  纯帧数据长度
    unsigned int        HideAlarmStatus;//遮挡侦测状态
    unsigned int        alarmstatus;  //报警状态暂不用, 用于保存wh(前两字节width, 后两字节height)
    unsigned long       mdstatus;     //移动侦测状态
    unsigned long long	timestamp;  //time stamp
    char                reserve[4]; //保留位(reserve[0]低4bit:samplerateBits, 中间2bit:bitwBits, 最高2bit:stereoBits)
    //主要用于存avi时判断是否有音频信息
    // reserve[3] 填充一个magic FHNP_FRAMEHEAD_TAIL_MAGIC   2015.08.25 add
} STRUCT_ATTR FHNP_Dev_FrameHead_t; 

#ifdef WIN32
#   pragma pack()
#endif

#endif
