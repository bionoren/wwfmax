//
//  DictionaryManager.h
//  wwfmax
//
//  Created by Bion Oren on 12/9/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#ifndef DICTIONARY_MANAGER
#define DICTIONARY_MANAGER

#import <stdbool.h>
#include <libkern/OSAtomic.h>

#define HASH_DEBUG (defined DEBUG && (NUM_THREADS == 1))

typedef struct dictStack {
    //current node list. This will get you a node, which lets you go down a level.
    int index; //index into the start of a child group in the nodeArray
    char childLetterFormatOffset; //english letter offset into the child group (a=0 to z)
    int childListFormat; //z-a bitstring (NOT index into the childLists table)
} dictStack;

typedef struct DictionaryManager {
    // The CWG basic-type arrays will have global scope to reduce function-argument overhead.
    int *nodeArray;
    int *listFormatArray;
    int *root_WTEOBL_Array;
    short *short_WTEOBL_Array;
    unsigned char *unsignedChar_WTEOBL_Array;
    // Needed for the CWG Hash-Function.
    int WTEOBL_Transition;
} DictionaryManager;

typedef struct DictionaryIterator {
    DictionaryManager *mgr;

    dictStack stack[BOARD_LENGTH + 1];
    //word we've currently built / are building
    char tmpWord[BOARD_LENGTH];
    //position in all of the above stacks
    int stackDepth;
    OSSpinLock lock;
#if HASH_DEBUG
    int lastHash;
#endif
} DictionaryIterator;

bool isValidWord(DictionaryIterator *itr, const char *TheCandidate, int CandidateLength);
int hashWord(DictionaryIterator *itr, const char *TheCandidate, const int CandidateLength);
int nextWord(DictionaryIterator *itr, char *outWord);
int numWords(DictionaryManager *mgr);
void resetIterator(DictionaryIterator *itr);

DictionaryManager *createDictManager(char *dictionary);
DictionaryIterator *createDictIterator(DictionaryManager *mgr);
DictionaryIterator *cloneDictIterator(DictionaryIterator *itr);
void freeDictManager(DictionaryManager *mgr);
void freeDictIterator(DictionaryIterator *itr);

#endif