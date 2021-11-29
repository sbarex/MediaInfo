//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef BridgeHeader_h
#define BridgeHeader_h

#import "webp/decode.h"

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavformat/avlanguage.h"

#define MAX_DATA_SIZE ((1 << 30) - 1)

#define BPG_HEADER_MAGIC 0x425047fb

struct AVDictionary {
    int count;
    AVDictionaryEntry *elems;
};
 
// /* return < 0 if error, otherwise the consumed length */
// static int get_ue32(uint32_t *pv, const uint8_t *buf, int len)
// {
//     const uint8_t *p;
//     uint32_t v;
//     int a;
//
//     if (len <= 0)
//         return -1;
//     p = buf;
//     a = *p++;
//     len--;
//     if (a < 0x80) {
//         *pv = a;
//         return 1;
//     } else if (a == 0x80) {
//         /* we don't accept non canonical encodings */
//         return -1;
//     }
//     v = a & 0x7f;
//     for(;;) {
//         if (len <= 0)
//             return -1;
//         a = *p++;
//         len--;
//         v = (v << 7) | (a & 0x7f);
//         if (!(a & 0x80))
//             break;
//     }
//     *pv = v;
//     return p - buf;
// }
//
// static int get_ue(uint32_t *pv, const uint8_t *buf, int len)
// {
//     int ret;
//     ret = get_ue32(pv, buf, len);
//     if (ret < 0)
//         return ret;
//     /* limit the maximum size to avoid overflows in buffer
//        computations */
//     if (*pv > MAX_DATA_SIZE)
//         return -1;
//     return ret;
// }

#endif /* BridgeHeader_h */
