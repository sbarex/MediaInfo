//
//  du.h
//  MediaInfo
//
//  Created by Sbarex on 06/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

#ifndef du_h
#define du_h

#include <stdio.h>

int du(const char *path, unsigned int *total, unsigned int *n, unsigned int timeout_s);

#endif /* du_h */
