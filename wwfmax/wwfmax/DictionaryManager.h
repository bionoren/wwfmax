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
    int index; //index into the start of a child group in the nodeArray
    int node;
} dictStack;

typedef int *restrict DictionaryManager;

typedef struct DictionaryIterator {
    DictionaryManager nodeArray;
    dictStack stack[BOARD_LENGTH + 1];
    //word we've currently built / are building
    char tmpWord[BOARD_LENGTH + 1];
    //position in all of the above stacks
    int stackDepth;
    int prefixLength;
    OSSpinLock lock;
} DictionaryIterator;

bool isValidWord(DictionaryManager nodeArray, const char *word, int length);
bool isValidPrefix(DictionaryManager nodeArray, const char *word, int length);
/** Returns true if the prefix is also a word, false otherwise (assumes 'word' is a valid prefix) */
bool isPrefixWord(DictionaryManager nodeArray, const char *word, int length);

int nextWord_threadsafe(DictionaryIterator *itr, char *outWord);
int nextWord(DictionaryIterator *itr, char *outWord);

int nextPrefix(DictionaryIterator *itr, char **outWord);
//NOTE: Resets the iterator
bool loadPrefix(DictionaryIterator *itr, const char *prefix, const int length);
//WARNING: Using this function with maxDepth < BOARD_LENGTH is UNDEFINED. Therefore, only use this method with maxDepth < BOARD_LENGTH on permutation dictionaries.
int nextWordWithPrefix(DictionaryIterator *itr, char *outWord, int maxDepth);

DictionaryIterator **iteratorsForLetterPair(DictionaryManager nodeArray, char c1, char c2, int **letterPairLookupTable);

void resetIterator(DictionaryIterator *itr);
void resetIteratorToPrefix(DictionaryIterator *itr);

DictionaryManager createDictManager(char *dictionary);
DictionaryIterator *createDictIterator(DictionaryManager nodeArray);
DictionaryIterator *cloneDictIterator(DictionaryIterator *itr);
void freeDictManager(DictionaryManager nodeArray);
void freeDictIterator(DictionaryIterator *itr);

typedef struct {
    DictionaryIterator *words;
    DictionaryManager rwords;
    DictionaryManager pwords;
    DictionaryManager rpwords;
    int **letterPairLookupTable;
} Dictionaries;

#endif