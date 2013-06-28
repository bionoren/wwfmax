//
//  DictionaryManager.m
//  wwfmax
//
//  Created by Bion Oren on 12/9/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import "DictionaryManager.h"
#import <string.h>
#import <stdio.h>
#import <stdlib.h>
#import "assert.h"
#import "CWGLib.h"

// Use the first two CWG arrays to return a boolean value indicating if "TheCandidate" word is in the lexicon.
bool isValidWord(DictionaryIterator *itr, const char *TheCandidate, int CandidateLength) {
    int CurrentNodeIndex = TheCandidate[0] - 'a' + 1;
    for(int i = 1; i < CandidateLength; i++) {
        int node = itr->mgr->nodeArray[CurrentNodeIndex];
        if(!(node & CHILD_MASK)) {
            return false;
        }

        bool extendedList = node & EXTENDED_LIST_FLAG;
        int CurrentChildListFormat = itr->mgr->listFormatArray[(node & LIST_FORMAT_INDEX_MASK) >> LIST_FORMAT_BIT_SHIFT];
        CurrentChildListFormat += extendedList << (CurrentChildListFormat >> NUMBER_OF_ENGLISH_LETTERS);

        int CurrentLetterPosition = TheCandidate[i] - 'a';
        if(!(CurrentChildListFormat & PowersOfTwo[CurrentLetterPosition])) {
            return false;
        } else {
            CurrentNodeIndex = (node & CHILD_MASK) + ListFormatPopCount(CurrentChildListFormat, CurrentLetterPosition) - 1;
        }
    }
    return itr->mgr->nodeArray[CurrentNodeIndex] & EOW_FLAG;
}

// Using a novel graph mark-up scheme, this function returns the hash index of "TheCandidate", and "0" if it does not exist.
// This function uses the additional 3 WTEOBL arrays.
int hashWord(DictionaryIterator *itr, const char *TheCandidate, const int CandidateLength) {
    int CurrentLetterPosition = TheCandidate[0] - 'a';
    int CurrentNodeIndex = CurrentLetterPosition + 1;
    int CurrentHashMarker = itr->mgr->root_WTEOBL_Array[CurrentNodeIndex];
    for(int i = 1; i < CandidateLength; i++) {
        int node = itr->mgr->nodeArray[CurrentNodeIndex];
        if(!(node & CHILD_MASK)) {
            return 0;
        }

        bool extendedList = node & EXTENDED_LIST_FLAG;
        int CurrentChildListFormat = itr->mgr->listFormatArray[(node & LIST_FORMAT_INDEX_MASK) >> LIST_FORMAT_BIT_SHIFT];
        CurrentChildListFormat += extendedList << (CurrentChildListFormat >> NUMBER_OF_ENGLISH_LETTERS);

        CurrentLetterPosition = TheCandidate[i] - 'a';
        if(!(CurrentChildListFormat & PowersOfTwo[CurrentLetterPosition])) {
            return 0;
        } else {
            CurrentNodeIndex = node & CHILD_MASK;
            int popCount = ListFormatPopCount(CurrentChildListFormat, CurrentLetterPosition) - 1;
            // Use "TheShort_WTEOBL_Array".
            if(CurrentNodeIndex < itr->mgr->WTEOBL_Transition) {
                CurrentHashMarker -= itr->mgr->short_WTEOBL_Array[CurrentNodeIndex];
                CurrentNodeIndex += popCount;
                CurrentHashMarker += itr->mgr->short_WTEOBL_Array[CurrentNodeIndex];
            } else { // Use "TheUnsignedChar_WTEOBL_Array".
                CurrentHashMarker -= itr->mgr->unsignedChar_WTEOBL_Array[CurrentNodeIndex - itr->mgr->WTEOBL_Transition];
                CurrentNodeIndex += popCount;
                CurrentHashMarker += itr->mgr->unsignedChar_WTEOBL_Array[CurrentNodeIndex - itr->mgr->WTEOBL_Transition];
            }
            if(itr->mgr->nodeArray[CurrentNodeIndex] & EOW_FLAG) {
                CurrentHashMarker--;
            }
        }
    }
    if(itr->mgr->nodeArray[CurrentNodeIndex] & EOW_FLAG) {
        return itr->mgr->root_WTEOBL_Array[1] - CurrentHashMarker;
    }
    return 0;
}

//cf. Justin-CWG-Search.c
int nextWord(DictionaryIterator *itr, char *outWord) {
    OSSpinLockLock(&itr->lock);
    if(itr->stackDepth < 0) {
        OSSpinLockUnlock(&itr->lock);
        return 0;
    }
    //1. go down as far as you can
    //2. go up 1 AND over 1 - childLetterIndexOffset++ (via childLetterFormatOffset += from childListFormat)
    //3. goto 1
    //stop if you've gone up past 0
    //break if you hit EOW

    assert(itr->stackDepth >= 0 && itr->stackDepth <= BOARD_LENGTH);
    //load state
    dictStack *item = &(itr->stack[itr->stackDepth]);
    
    //if there are unexplored children
    //else drop back until there are unexplored children
    if(item->index == 0) {
        do {
            unsigned int offset = ffs(item->childListFormat);
            if(offset != 0) {
                item->childListFormat >>= offset;
                item->childLetterFormatOffset += offset;
                assert(item->childLetterFormatOffset <= 'z');
                ++item->index;
                goto LOOP_END;
            }
            item--;
        } while(--(itr->stackDepth) >= 0);
        OSSpinLockUnlock(&itr->lock);
        return 0;
    }
LOOP_END:;
    
    //and explore them
    int node;
    do {
        //get the node
        node = itr->mgr->nodeArray[item->index];

        //store the letter and go down
        itr->tmpWord[itr->stackDepth++] = item->childLetterFormatOffset;
        assert(itr->stackDepth <= BOARD_LENGTH);

        //setup the next node
        item++;
        item->index = node & CHILD_MASK;

        int childListFormat = itr->mgr->listFormatArray[(node & LIST_FORMAT_INDEX_MASK) >> LIST_FORMAT_BIT_SHIFT];
        if(node & EXTENDED_LIST_FLAG) {
            childListFormat += 1 << (childListFormat >> NUMBER_OF_ENGLISH_LETTERS);
        }
        item->childListFormat = childListFormat & 0x03FFFFFF;

        //seek to the first letter in the list
        char offset = (char)ffs(item->childListFormat);
        item->childLetterFormatOffset = offset + 'a' - 1;
        item->childListFormat >>= offset;
        assert(item->childLetterFormatOffset <= 'z');
    } while(!(node & EOW_FLAG));
    
    assert(itr->stackDepth > 1 && itr->stackDepth <= BOARD_LENGTH);
    for(int i = 0; i < BOARD_LENGTH; i++) {
        outWord[i] = itr->tmpWord[i];
    }
    //NSLog(@"Evaluating %.*s", length, tmpWord);

#if HASH_DEBUG
    assert(hashWord(itr, outWord, itr->stackDepth) == ++(itr->lastHash));
    assert(isValidWord(itr, outWord, itr->stackDepth));
#endif
    int ret = itr->stackDepth;
    OSSpinLockUnlock(&itr->lock);
    return ret;
}

int numWords(DictionaryManager *mgr) {
    return mgr->root_WTEOBL_Array[1];
}

void resetIterator(DictionaryIterator *itr) {
#ifdef DEBUG
    printf("Reseting dictionary iterator...\n");
#endif
    itr->stack[0].index = 1;
    itr->stack[0].childLetterFormatOffset = 'a';
    itr->stack[0].childListFormat = 0x01FFFFFF;
    itr->stackDepth = 0;
#if HASH_DEBUG
    itr->lastHash = 0;
#endif
}

DictionaryManager *createDictManager(char *dictionary) {
    DictionaryManager *ret = malloc(sizeof(DictionaryManager));

    // Array size variables.
    int NodeArraySize;
    int ListFormatArraySize;
    int Root_WTEOBL_ArraySize;
    int Short_WTEOBL_ArraySize;
    int UnsignedChar_WTEOBL_ArraySize;
    
    // Read the CWG graph, from the "GRAPH_DATA" file, into the global arrays.
    FILE *data = fopen(dictionary, "rb");
    assert(data);
    
    // Read the array sizes.
    fread(&NodeArraySize, sizeof(int), 1, data);
    assert(NodeArraySize > 0);
    fread(&ListFormatArraySize, sizeof(int), 1, data);
    assert(ListFormatArraySize > 0);
    fread(&Root_WTEOBL_ArraySize, sizeof(int), 1, data);
    assert(Root_WTEOBL_ArraySize > 0);
    fread(&Short_WTEOBL_ArraySize, sizeof(int), 1, data);
    assert(Short_WTEOBL_ArraySize > 0);
    fread(&UnsignedChar_WTEOBL_ArraySize, sizeof(int), 1, data);
    assert(UnsignedChar_WTEOBL_ArraySize > 0);
    
    // Allocate memory to hold the arrays.
    ret->nodeArray = (int *)malloc(NodeArraySize*sizeof(int));
    ret->listFormatArray = (int *)malloc(ListFormatArraySize*sizeof(int));
    ret->root_WTEOBL_Array = (int *)malloc(Root_WTEOBL_ArraySize*sizeof(int));
    ret->short_WTEOBL_Array = (short int *)malloc(Short_WTEOBL_ArraySize*sizeof(short int));
    ret->unsignedChar_WTEOBL_Array = (unsigned char *)malloc(UnsignedChar_WTEOBL_ArraySize*sizeof(unsigned char));
    
    // Read the 5 arrays into memory.
    fread(ret->nodeArray, sizeof(int), NodeArraySize, data);
    fread(ret->listFormatArray, sizeof(int), ListFormatArraySize, data);
    fread(ret->root_WTEOBL_Array, sizeof(int), Root_WTEOBL_ArraySize, data);
    fread(ret->short_WTEOBL_Array, sizeof(short int), Short_WTEOBL_ArraySize, data);
    fread(ret->unsignedChar_WTEOBL_Array, sizeof(unsigned char), UnsignedChar_WTEOBL_ArraySize, data);
    
    fclose(data);
    
    // Make the proper assignments and adjustments to use the CWG.
    ret->WTEOBL_Transition = Short_WTEOBL_ArraySize;

    return ret;
}

DictionaryIterator *createDictIterator(DictionaryManager *mgr) {
    DictionaryIterator *ret = malloc(sizeof(DictionaryIterator));
    ret->mgr = mgr;
    resetIterator(ret);
    ret->lock = OS_SPINLOCK_INIT;

    return ret;
}

DictionaryIterator *cloneDictIterator(DictionaryIterator *itr) {
    return createDictIterator(itr->mgr);
}

void freeDictManager(DictionaryManager *mgr) {
    free(mgr->nodeArray);
    free(mgr->listFormatArray);
    free(mgr->root_WTEOBL_Array);
    free(mgr->short_WTEOBL_Array);
    free(mgr->unsignedChar_WTEOBL_Array);
    free(mgr);
}

void freeDictIterator(DictionaryIterator *itr) {
    free(itr);
}