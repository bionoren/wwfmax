//
//  CWGLib.c
//  wwfmax
//
//  Created by Bion Oren on 11/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "CWGLib.h"

// This is an important function involved in any movement through the CWG.
// The "CompleteChildList" is masked according to "LetterPosition", and then a byte-wise pop-count is carried out. ('A' => 0).
// The function retruns the corresponding offset for the "LetterPosition"th letter.
int ListFormatPopCount(int CompleteChildList, int LetterPosition){
    // This jump-table eliminates needless instructions and cumbersome conditional tests.
    const static void *PositionJumpTable[NUMBER_OF_ENGLISH_LETTERS] = { &&On, &&On, &&On, &&On, &&On, &&On, &&On, &&On, &&Tw, &&Tw, &&Tw, &&Tw, &&Tw, &&Tw, &&Tw, &&Tw, &&Th, &&Th, &&Th, &&Th, &&Th, &&Th, &&Th, &&Th, &&Fo, &&Fo };
    int Result = 0;
    // By casting the agrument variable "CompleteChildList" as an "unsigned char *" we can access each byte within it using simple arithmetic.
    // Computer-programs in C use "little-endian" byte-order.  The least significant bit comes first.
    unsigned char *ByteZero = (unsigned char *)&CompleteChildList;
    
    // Mask "CompleteChildList" according to "LetterPosition".
    CompleteChildList &= ChildListMasks[LetterPosition];
    // Query the "PopCountTable" a minimum number of times.
    goto *PositionJumpTable[LetterPosition];
Fo:
    Result += PopCountTable[*(ByteZero + 3)];
Th:
    Result += PopCountTable[*(ByteZero + 2)];
Tw:
    Result += PopCountTable[*(ByteZero + 1)];
On:
    Result += PopCountTable[*ByteZero];
    return Result;
}

// This simple function clips off the extra chars for each "fgets()" line.  Works for Linux and Windows text format.
void CutOffExtraChars(char *ThisLine) {
    if(ThisLine[strlen(ThisLine) - 2] == '\r') {
        ThisLine[strlen(ThisLine) - 2] = '\0';
    } else if (ThisLine[strlen(ThisLine) - 1] == '\n') {
        ThisLine[strlen(ThisLine) - 1] = '\0';
    }
}

// This Function converts any lower case letters inside "RawWord" to capitals, so that the whole string is made of capital letters.
void MakeMeAllCapital(char *RawWord) {
    size_t Length = strlen(RawWord);
    for(int i = 0; i < Length; i++) {
        if(RawWord[i] >= 'a' && RawWord[i] <= 'z') {
            RawWord[i] = RawWord[i] - LOWER_IT;
        }
    }
}