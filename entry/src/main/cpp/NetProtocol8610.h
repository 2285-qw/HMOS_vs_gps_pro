#ifndef _NET_PROTOCOL_8610_H_
#define _NET_PROTOCOL_8610_H_

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

typedef struct 
{
    unsigned char flag[4];
    unsigned char encid;
    unsigned char frame_num;
    unsigned char block_num;
    unsigned char block_flag;
    unsigned int  block_len;
} STRUCT_ATTR FHNP_61_BlockHead_t;

typedef struct 
{
#ifdef WIN32
    unsigned __int64    timestamp;
#else
    unsigned long long  timestamp;
#endif
    unsigned char       avopt;
    unsigned char       vformat;
    unsigned char       aformat;
    unsigned char       restart;
    unsigned short      width;
    unsigned short      height;
    unsigned int		bitrate;
    unsigned int        frame_len;
    unsigned char       frame_rate;
    unsigned char       audio_info;
    unsigned char       alarm_info;
    unsigned char       reserved;
} STRUCT_ATTR FHNP_61_FrameInfo_t; 

typedef struct 
{ 
    unsigned char       FrmHd[4];
    unsigned char       chan;
    unsigned char       Vmsflag;
    unsigned char       AVOption;
    unsigned char       VideoFormat;
    unsigned char       AudioFormat;
    unsigned char       restart_flag;    
    unsigned char       frmnum;
    unsigned char       Framerate;
    unsigned int		Bitrate;
    int                 framelen;
    unsigned int        HideAlarmStatus;
    unsigned int        alarmstatus;
    unsigned int        mdstatus;
#ifdef WIN32
    unsigned __int64    timestamp;
#else
    unsigned long long  timestamp;
#endif
    char                reserve[4];
} STRUCT_ATTR FHNP_61_FrameHead_t;

#ifdef WIN32
#   pragma pack()
#endif

#endif
