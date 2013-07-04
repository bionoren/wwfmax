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

typedef struct dictStack {
    //current node list. This will get you a node, which lets you go down a level.
    unsigned int index; //index into the start of a child group in the nodeArray
    int node;
} dictStack;

typedef struct DictionaryManager {
    int *nodeArray;
} DictionaryManager;

typedef struct DictionaryIterator {
    DictionaryManager *mgr;

    dictStack stack[BOARD_LENGTH + 1];
    //word we've currently built / are building
    char tmpWord[BOARD_LENGTH + 1];
    //position in all of the above stacks
    int stackDepth;
    OSSpinLock lock;
} DictionaryIterator;

bool isValidWord(DictionaryIterator *itr, const char *TheCandidate, int CandidateLength);
int nextWord_threadsafe(DictionaryIterator *itr, char *outWord);
int nextWord(DictionaryIterator *itr, char *outWord);
void resetIterator(DictionaryIterator *itr);

DictionaryManager *createDictManager(char *dictionary);
DictionaryIterator *createDictIterator(DictionaryManager *mgr);
DictionaryIterator *cloneDictIterator(DictionaryIterator *itr);
void freeDictManager(DictionaryManager *mgr);
void freeDictIterator(DictionaryIterator *itr);

#endif