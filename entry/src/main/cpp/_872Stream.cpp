//
// 872 视频流解析
// Created by Administrator on 2021/6/1 0001.
//

#include <string>
#include "_872Stream.h"

#define IMAGE_BUFF_MAX             (512 * 1024)
#define IMAGE_INDEX_MAX            (2)
#define IMAGE_FRAME_PACKAGE_MAX    (100)
#define IMAGE_FRAME_HEAD           "@@"
#define IMAGE_FRAME_HEAD_LEN       (8)    // "@@"(2B) + image_index(2B) + frame_total(1B) + frame_index(1B) + image_length(2B) + data
#define IMAGE_FRAME_TAIL_LEN       (2)    // "##"
#define IMAGE_FRAME_DATA_LENGTH    (1400)

typedef struct {
    int image_index;
    unsigned char frame_total;
    unsigned char frame_index;
    long image_total_length;
    int package_length;
} udp_image_t;

static udp_image_t image_data[IMAGE_INDEX_MAX] = {0};
static unsigned char image_buffer[IMAGE_INDEX_MAX][IMAGE_BUFF_MAX];
static char package_flag[IMAGE_INDEX_MAX][IMAGE_FRAME_PACKAGE_MAX];


char *p_image_current;
long totalbytes = 0;
int iamge_index = 0;  //recv current picture index

udp_image_t udp_pack;

int analysis(int recvbytes, char *stream, char *&image_temp_buffer) {
    memset(&udp_pack, 0, sizeof(udp_image_t));

    if (recvbytes <=
        IMAGE_FRAME_HEAD_LEN) { // "@@"(2B) + image_index(2B) + frame_total(1B) + frame_inedx(1B) + image_length(2B) + data
        return 0;
    }

    if (memcmp(stream, IMAGE_FRAME_HEAD, 2))    //check "@@"
    {
        return 0;
    }

    udp_pack.image_index = stream[2] |
                           ((unsigned int) (stream[3]) << 8);      //get image index
    udp_pack.frame_total = stream[4];
    udp_pack.frame_index = stream[5];                                                   //get currentImage framepack index
    udp_pack.package_length = stream[6] | ((unsigned int) (stream[7])
            << 8);   //current framepack length
    if ((recvbytes != udp_pack.package_length) || (udp_pack.frame_total == 0) ||
        (udp_pack.frame_index > IMAGE_FRAME_PACKAGE_MAX)) {
        return 0;
    }

    int i = 0;
    for (i = 0; i < IMAGE_INDEX_MAX; i++) {
        if (udp_pack.image_index == image_data[i].image_index) {
            iamge_index = i;      //search (n) picture in index buffer
            break;
        }
    }

    if (i == IMAGE_INDEX_MAX)    //index buffer empty, recv a new picture
    {
        if (image_data[0].image_index <= image_data[1].image_index) {
            iamge_index = 0;
        } else {
            iamge_index = 1;
        }

        memset(&package_flag[iamge_index], 0, IMAGE_FRAME_PACKAGE_MAX);
        memset(&image_data[iamge_index], 0, sizeof(udp_image_t));
        image_data[iamge_index].image_total_length = 0;
        image_data[iamge_index].image_index = udp_pack.image_index;

    }
    image_data[iamge_index].frame_total = udp_pack.frame_total;
    image_data[iamge_index].frame_index = udp_pack.frame_index;
    image_data[iamge_index].package_length = udp_pack.package_length;
    if (image_data[iamge_index].frame_index > image_data[iamge_index].frame_total) {
        return 0;;   //protocol err
    }

    i = image_data[iamge_index].frame_index;
    if (package_flag[iamge_index][i] == 0) {
        p_image_current = (char *) (&image_buffer[iamge_index]);
        memcpy(p_image_current + image_data[iamge_index].frame_index *
                                 (IMAGE_FRAME_DATA_LENGTH -
                                  (IMAGE_FRAME_HEAD_LEN + IMAGE_FRAME_TAIL_LEN)),
               stream + IMAGE_FRAME_HEAD_LEN,
               image_data[iamge_index].package_length -
               (IMAGE_FRAME_HEAD_LEN + IMAGE_FRAME_TAIL_LEN));
        image_data[iamge_index].image_total_length += (image_data[iamge_index].package_length -
                                                       (IMAGE_FRAME_HEAD_LEN +
                                                        IMAGE_FRAME_TAIL_LEN));
    }
    package_flag[iamge_index][i] = 1;

    i = 0;
    int count = 0;
    for (i = 0; i <
                image_data[iamge_index].frame_total; i++) //check a picture data had receive complete
    {
        if (package_flag[iamge_index][i] == 0) {
            break;
        } else {
            count += 1;
        }
    }
    if (count == image_data[iamge_index].frame_total) {
        memcpy(image_temp_buffer, p_image_current, image_data[iamge_index].image_total_length);
        totalbytes = image_data[iamge_index].image_total_length;
        memset(&image_data[iamge_index], 0, sizeof(udp_image_t));
        memset(&package_flag[iamge_index], 0, IMAGE_FRAME_PACKAGE_MAX);
    } else {
        return 0;
    }

    return (int) totalbytes;
}



