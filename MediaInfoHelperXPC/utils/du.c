//
//  du.c
//  MediaInfo
//
//  Created by Simone Baldissini on 06/03/22.
//  Copyright © 2022 sbarex. All rights reserved.
//

#include "du.h"
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <ftw.h>
#include <time.h>

static unsigned int _total = 0;
static unsigned int _n = 0;
static clock_t start;
static clock_t delay;

int sum(const char *fpath, const struct stat *sb, int typeflag) {
    _total += sb->st_size;
    _n += 1;
    /*
    const char *s;
    switch (typeflag) {
        case FTW_F:
            s = "File.";
            break;
        case FTW_D:
            s = "Directory.";
            break;
        case FTW_DNR:
            s = "Directory without read permission.";
            break;
        case FTW_DP:
            s = "Directory with subdirectories visited.";
            break;
        case FTW_NS:
            s = "Unknown type; stat() failed.";
            break;
        case FTW_SL:
            s = "Symbolic link.";
            break;
        case FTW_SLN:
            s = "Sym link that names a nonexistent file.";
            break;
    }
    printf("%d %s: %s\n", _n, s, fpath);
     */
    if ((clock() - start) >= delay) {
        return 1;
    }
    return 0;
}

int du(const char *path, unsigned int *total, unsigned int *n, unsigned int timeout_s) {
    start = clock();
    delay = timeout_s * CLOCKS_PER_SEC;
    
    if (access(path, R_OK)) {
        return 1;
    }
    if (ftw(path, &sum, 1)) {
        perror("ftw");
        return 2;
    }
    (*total) = _total;
    (*n) = _n;
    printf("%s: %u (%d)\n", path, _total, _n);
    return 0;
}
