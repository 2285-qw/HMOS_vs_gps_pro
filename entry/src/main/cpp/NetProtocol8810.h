#ifndef _NET_PROTOCOL_8810_H_
#define _NET_PROTOCOL_8810_H_

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
} STRUCT_ATTR FHNP_81_FrameHead_t;

#ifdef WIN32
#   pragma pack()
#endif

#endif
