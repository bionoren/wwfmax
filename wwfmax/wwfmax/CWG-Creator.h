//
//  CWG-Creator.h
//  wwfmax
//
//  Created by Bion Oren on 11/10/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#ifndef wwfmax_CWG_Creator_h
#define wwfmax_CWG_Creator_h

#import <stdbool.h>

enum LIST_COMPACTION {
    LIST_COMPACTION_NONE = 0,
    LIST_COMPACTION_ADDITIVE = 1,
    LIST_COMPACTION_SHIFTED = 2,
    LIST_COMPACTION_ROTATED = 4,
    LIST_COMPACTION_ALL = LIST_COMPACTION_ADDITIVE | LIST_COMPACTION_SHIFTED | LIST_COMPACTION_ROTATED
};

typedef struct CWGOptions {
    int maxWordLength;
    //specifying multiple compaction methods will use the most space-efficient one
    int compactionMethod;
} CWGOptions;

typedef struct CWGStructure {
    char *filename;
    enum LIST_COMPACTION compactionMethod;
    unsigned int maxWordLength;
    unsigned int childMask;
    unsigned int listMask;
    unsigned int listShift;
} CWGStructure;

CWGStructure *createDataStructure(const WordInfo *info, const char *outFile, CWGOptions options);

#endif