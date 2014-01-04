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
#import "dawg.h"

bool isValidWord(DictionaryManager nodeArray, const char *word, int length) {
    int *node = &nodeArray[word[0] - 'a' + 1]; //root node
    for(int i = 1; i < length; i++) {
        if(!(*node & CHILD_INDEX_BIT_MASK)) {
            return false;
        }

        int letterIndex = word[i];
        for(node = &nodeArray[(*node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT]; !(*node & END_OF_LIST_BIT_MASK) && letterIndex != (*node & LETTER_BIT_MASK); node++);
        if(letterIndex != (*node & LETTER_BIT_MASK)) {
            return false;
        }
    }
    return *node & END_OF_WORD_BIT_MASK;
}

bool isValidPrefix(DictionaryManager nodeArray, const char *word, int length) {
    int *node = &nodeArray[word[0] - 'a' + 1]; //root node
    for(int i = 1; i < length; ++i) {
        if(!(*node & CHILD_INDEX_BIT_MASK)) {
            return false;
        }

        int targetLetter = word[i];
        for(node = &nodeArray[(*node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT]; targetLetter != (*node & LETTER_BIT_MASK) && (*node & END_OF_LIST_BIT_MASK) == 0; ++node);
        if(targetLetter != (*node & LETTER_BIT_MASK)) {
            return false;
        }
    }
    return true;
}

bool isPrefixWord(DictionaryManager nodeArray, const char *word, int length) {
    int *node = &nodeArray[word[0] - 'a' + 1]; //root node
    for(int i = 1; i < length; ++i) {
        assert(*node & CHILD_INDEX_BIT_MASK);

        int targetLetter = word[i];
        for(node = &nodeArray[(*node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT]; targetLetter != (*node & LETTER_BIT_MASK) && (*node & END_OF_LIST_BIT_MASK) == 0; ++node);
        assert(targetLetter == (*node & LETTER_BIT_MASK));
        assert((*node & LETTER_BIT_MASK) == word[i]);
    }
    return (*node & END_OF_WORD_BIT_MASK);
}

int nextWord_threadsafe(DictionaryIterator *itr, char *outWord) {
    OSSpinLockLock(&itr->lock);
    int ret = nextWord(itr, outWord);
    OSSpinLockUnlock(&itr->lock);
    return ret;
}

int nextWord(DictionaryIterator *itr, char *outWord) {
    assert(itr->stackDepth >= 0 && itr->stackDepth <= BOARD_LENGTH);

    dictStack *restrict item = &(itr->stack[itr->stackDepth]);
    if(!item->index) {
        item--;
        itr->stackDepth--;
        do {
            assert(item->node);
            if(item->node & END_OF_LIST_BIT_MASK) {
                item--;
            } else {
                item->node = itr->nodeArray[++item->index];
                goto LOOP_END2;
            }
        } while(itr->stackDepth-- > 0);
        return 0;
    }
LOOP_END2:;

    int node = item->node;
    bool eow;
    do {
        eow = node & END_OF_WORD_BIT_MASK;

        //store the letter and go down
        itr->tmpWord[itr->stackDepth++] = node & LETTER_BIT_MASK;
        assert(itr->stackDepth <= BOARD_LENGTH);

        //setup the next node
        item = &itr->stack[itr->stackDepth];
        item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        item->node = node = itr->nodeArray[item->index];
    } while(!eow);

    assert(itr->stackDepth > 1 && itr->stackDepth <= BOARD_LENGTH);
    assert(BOARD_LENGTH + 1 == 16 && sizeof(long) == 8);
    for(int i = 0; i < 2; i++) {
        ((long*restrict)outWord)[i] = ((long*restrict)itr->tmpWord)[i];
    }
    //printf("Evaluating %.*s\n", itr->stackDepth, outWord);

    assert(isValidWord(itr->nodeArray, outWord, itr->stackDepth));
    return itr->stackDepth;
}

int nextPrefix(DictionaryIterator *itr, char **outWord) {
    assert(itr->stackDepth >= 0 && itr->stackDepth <= BOARD_LENGTH);

    dictStack *restrict item = &(itr->stack[itr->stackDepth]);
    if(!item->index) {
        item--;
        itr->stackDepth--;
        do {
            assert(item->node);
            if(item->node & END_OF_LIST_BIT_MASK) {
                item--;
            } else {
                item->node = itr->nodeArray[++item->index];
                goto LOOP_END2;
            }
        } while(itr->stackDepth-- > 0);
        return 0;
    }
LOOP_END2:;

    int node = item->node;
    //store the letter and go down
    itr->tmpWord[itr->stackDepth++] = node & LETTER_BIT_MASK;
    assert(itr->stackDepth <= BOARD_LENGTH);

    //setup the next node
    item = &itr->stack[itr->stackDepth];
    item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
    item->node = node = itr->nodeArray[item->index];

    assert(itr->stackDepth >= 1 && itr->stackDepth <= BOARD_LENGTH);
    *outWord = itr->tmpWord;
    //NSLog(@"Evaluating %.*s", length, tmpWord);

    return itr->stackDepth;
}

bool loadPrefix(DictionaryIterator *itr, const char *restrict prefix, const int length) {
    resetIterator(itr);

    int index = prefix[0] - 'a' + 1;
    int node = itr->nodeArray[index];
    itr->tmpWord[0] = *prefix++;

    for(int i = 1; i < length; ++i) {
#if DEBUG
        itr->stack[i - 1].index = index;
        itr->stack[i - 1].node = node;
#endif
        assert(node & CHILD_INDEX_BIT_MASK);

        char letterIndex = *prefix++;
        itr->tmpWord[i] = letterIndex;

        //setup the next node
        for(index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT; letterIndex != (itr->nodeArray[index] & LETTER_BIT_MASK); ++index) {
            assert(!(itr->nodeArray[index] & END_OF_LIST_BIT_MASK));
        }
        assert(letterIndex == (itr->nodeArray[index] & LETTER_BIT_MASK));
        node = itr->nodeArray[index];
    }
    itr->prefixLength = length;
    itr->stackDepth = length;

    dictStack *item = &(itr->stack[length]);
    item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
    item->node = itr->nodeArray[item->index];
#if DEBUG
    itr->stack[length - 1].index = index;
    itr->stack[length - 1].node = node;
#endif
    return true;
}

int nextWordWithPrefix(DictionaryIterator *itr, char *outWord, int maxDepth) {
    assert(itr->prefixLength > 0);
    assert(itr->stackDepth >= itr->prefixLength - 1);

    dictStack *restrict item = &(itr->stack[itr->stackDepth]);
START:;
    if(!item->index || itr->stackDepth >= maxDepth) {
        item--;
        while(--itr->stackDepth > itr->prefixLength) {
            assert(item->node);
            if(item->node & END_OF_LIST_BIT_MASK || itr->stackDepth >= maxDepth) {
                item--;
            } else {
                item->node = itr->nodeArray[++item->index];
                goto LOOP_END2;
            }
        }
        return 0;
    }
LOOP_END2:;

    int node = item->node;
    bool eow;
    do {
        eow = node & END_OF_WORD_BIT_MASK;

        //store the letter and go down
        itr->tmpWord[itr->stackDepth++] = node & LETTER_BIT_MASK;

        //setup the next node
        item = &itr->stack[itr->stackDepth];
        item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        item->node = node = itr->nodeArray[item->index];

        if(itr->stackDepth > maxDepth) {
            goto START;
        }
    } while(!eow);

    assert(itr->stackDepth > itr->prefixLength && itr->stackDepth <= maxDepth);
    assert(BOARD_LENGTH + 1 == 16 && sizeof(long) == 8);
    for(int i = 0; i < 2; i++) {
        ((long*restrict)outWord)[i] = ((long*restrict)itr->tmpWord)[i];
    }
    //NSLog(@"Evaluating %.*s", length, tmpWord);

    //assert(isValidWord(itr->mgr, outWord, itr->stackDepth));
    return itr->stackDepth;
}

DictionaryIterator **iteratorsForLetterPair(DictionaryManager nodeArray, char c1, char c2, int **letterPairLookupTable) {
    int *row = letterPairLookupTable[(c1 - 'a') + (c2 - 'a') * 26];
    if(row[0] == 0) {
        return NULL;
    }
    DictionaryIterator **ret = calloc(row[0] + 1, sizeof(DictionaryIterator*));
    for(int i = 1; i < row[0] + 1; i++) {
        DictionaryIterator *itr = createDictIterator(nodeArray);
        itr->prefixLength = 2;
        //load the first character
        int node;
        itr->stack[itr->stackDepth].index = row[i];
        itr->stack[itr->stackDepth].node = node = nodeArray[itr->stack[itr->stackDepth].index];
        itr->stackDepth++;
        //load the second character
        itr->stack[itr->stackDepth].index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        itr->stack[itr->stackDepth].node = node = nodeArray[itr->stack[itr->stackDepth].index];
        while((node & LETTER_BIT_MASK) != c2) {
            assert(!(node & END_OF_LIST_BIT_MASK));
            itr->stack[itr->stackDepth].index++;
            itr->stack[itr->stackDepth].node = node = nodeArray[itr->stack[itr->stackDepth].index];
        }
        itr->stackDepth++;
        itr->stack[itr->stackDepth].index = node = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        itr->stack[itr->stackDepth].node = nodeArray[itr->stack[itr->stackDepth].index];

        itr->tmpWord[0] = c1;
        itr->tmpWord[1] = c2;
        ret[i - 1] = itr;
    }

    return ret;
}

void resetIterator(DictionaryIterator *itr) {
    itr->stack[0].index = 1;
    itr->stack[0].node = itr->nodeArray[itr->stack[0].index];
    itr->stackDepth = 0;
    itr->prefixLength = 0;
}

void resetIteratorToPrefix(DictionaryIterator *itr) {
    loadPrefix(itr, itr->tmpWord, itr->prefixLength);
}

#pragma mark -  Setup / Teardown

DictionaryManager createDictManager(char *dictionary) {
    FILE *data = fopen(dictionary, "rb");
    assert(data);

    int numNodes;
	fread(&numNodes, sizeof(int), 1, data);
	DictionaryManager ret = (int*)malloc(numNodes * sizeof(int));
	fread(ret, sizeof(int), numNodes, data);
    
    fclose(data);

    return ret;
}

DictionaryIterator *createDictIterator(DictionaryManager nodeArray) {
    DictionaryIterator *ret = malloc(sizeof(DictionaryIterator));
    ret->nodeArray = nodeArray;
    resetIterator(ret);
    ret->lock = OS_SPINLOCK_INIT;

    return ret;
}

DictionaryIterator *cloneDictIterator(DictionaryIterator *itr) {
    return createDictIterator(itr->nodeArray);
}

void freeDictManager(DictionaryManager nodeArray) {
    free(nodeArray);
}

void freeDictIterator(DictionaryIterator *itr) {
    free(itr);
}