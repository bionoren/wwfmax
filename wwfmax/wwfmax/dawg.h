//
//  dawg.h
//  wwfmax
//
//  Created by Bion Oren on 11/10/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#ifndef wwfmax_dawg_h
#define wwfmax_dawg_h

#import "tnode.h"

struct dawg {
    int NumberOfTotalWords;
    int NumberOfTotalNodes;
    TnodePtr First;
};

typedef struct dawg Dawg;
typedef Dawg* DawgPtr;

DawgPtr DawgInit(void);
void DawgAddWord(DawgPtr ThisDawg, char * NewWord);
void DawgGraphTabulate(DawgPtr ThisDawg, int* Count, int maxWordLength);
void DawgLawnMower(DawgPtr ThisDawg);

#endif