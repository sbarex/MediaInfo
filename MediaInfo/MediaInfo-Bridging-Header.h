//
//  MediaInfo-Bridging-Header.h
//  MediaInfo
//
//  Created by Sbarex on 15/01/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

#ifndef MediaInfo_Bridging_Header_h
#define MediaInfo_Bridging_Header_h

#include "libarchive/include/archive.h"
#include "libarchive/include/archive_entry.h"
#define FORMAT_AE_IFMT      0170000
#define FORMAT_AE_IFREG     0100000
#define FORMAT_AE_IFLNK     0120000
#define FORMAT_AE_IFSOCK    0140000
#define FORMAT_AE_IFCHR     0020000
#define FORMAT_AE_IFBLK     0060000
#define FORMAT_AE_IFDIR     0040000
#define FORMAT_AE_IFIFO     0010000

#endif /* MediaInfo_Bridging_Header_h */
