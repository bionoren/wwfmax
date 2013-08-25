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

bool isValidWord(DictionaryManager *mgr, const char *word, int length) {
    int *node = &mgr->nodeArray[word[0] - 'a' + 1]; //root node
    for(int i = 1; i < length; i++) {
        if(!(*node & CHILD_INDEX_BIT_MASK)) {
            return false;
        }

        int letterIndex = word[i];
        for(node = &mgr->nodeArray[(*node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT]; !(*node & END_OF_LIST_BIT_MASK) && letterIndex != (*node & LETTER_BIT_MASK); node++);
        if(letterIndex != (*node & LETTER_BIT_MASK)) {
            return false;
        }
    }
    return *node & END_OF_WORD_BIT_MASK;
}

bool isValidPrefix(DictionaryManager *mgr, const char *word, int length) {
    int *node = &mgr->nodeArray[word[0] - 'a' + 1]; //root node
    for(int i = 1; i < length; ++i) {
        if(!(*node & CHILD_INDEX_BIT_MASK)) {
            return false;
        }

        int letterIndex = word[i];
        for(node = &mgr->nodeArray[(*node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT]; letterIndex != (*node & LETTER_BIT_MASK); ++node);
        if(letterIndex != (*node & LETTER_BIT_MASK)) {
            return false;
        }
    }
    return true;
}

bool isPrefixWord(DictionaryManager *mgr, const char *word, int length) {
    int *node = &mgr->nodeArray[word[0] - 'a' + 1]; //root node
    for(int i = 1; i < length; ++i) {
        assert(*node & CHILD_INDEX_BIT_MASK);

        int letterIndex = word[i];
        for(node = &mgr->nodeArray[(*node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT]; letterIndex != (*node & LETTER_BIT_MASK); ++node);
        assert(letterIndex == (*node & LETTER_BIT_MASK));
    }
    return (*node & END_OF_WORD_BIT_MASK);
}

int nextWord_threadsafe(DictionaryIterator *itr, char *outWord) {
    OSSpinLockLock(&itr->lock);
    if(itr->stackDepth < 0) {
        OSSpinLockUnlock(&itr->lock);
        return 0;
    }

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
                item->node = itr->mgr->nodeArray[++item->index];
                goto LOOP_END;
            }
        } while(itr->stackDepth-- > 0);
        OSSpinLockUnlock(&itr->lock);
        return 0;
    }
LOOP_END:;

    bool eow;
    int node = item->node;
    do {
        eow = node & END_OF_WORD_BIT_MASK;

        //store the letter and go down
        itr->tmpWord[itr->stackDepth++] = node & LETTER_BIT_MASK;
        assert(itr->stackDepth <= BOARD_LENGTH);

        //setup the next node
        item = &itr->stack[itr->stackDepth];
        item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        item->node = node = itr->mgr->nodeArray[item->index];
    } while(!eow);
    
    assert(itr->stackDepth > 1 && itr->stackDepth <= BOARD_LENGTH);
    assert(BOARD_LENGTH + 1 == 16 && sizeof(long) == 8);
    for(int i = 0; i < 2; i++) {
        ((long*restrict)outWord)[i] = ((long*restrict)itr->tmpWord)[i];
    }
    //NSLog(@"Evaluating %.*s", length, tmpWord);

    assert(isValidWord(itr->mgr, outWord, itr->stackDepth));
    int ret = itr->stackDepth;
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
                item->node = itr->mgr->nodeArray[++item->index];
                goto LOOP_END2;
            }
        } while(itr->stackDepth-- > 0);
        return 0;
    }
LOOP_END2:;

    bool eow;
    int node = item->node;
    do {
        eow = node & END_OF_WORD_BIT_MASK;

        //store the letter and go down
        itr->tmpWord[itr->stackDepth++] = node & LETTER_BIT_MASK;
        assert(itr->stackDepth <= BOARD_LENGTH);

        //setup the next node
        item = &itr->stack[itr->stackDepth];
        item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        item->node = node = itr->mgr->nodeArray[item->index];
    } while(!eow);

    assert(itr->stackDepth > 1 && itr->stackDepth <= BOARD_LENGTH);
    assert(BOARD_LENGTH + 1 == 16 && sizeof(long) == 8);
    for(int i = 0; i < 2; i++) {
        ((long*restrict)outWord)[i] = ((long*restrict)itr->tmpWord)[i];
    }
    //NSLog(@"Evaluating %.*s", length, tmpWord);

    assert(isValidWord(itr->mgr, outWord, itr->stackDepth));
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
                item->node = itr->mgr->nodeArray[++item->index];
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
    item->node = node = itr->mgr->nodeArray[item->index];

    assert(itr->stackDepth >= 1 && itr->stackDepth <= BOARD_LENGTH);
    *outWord = itr->tmpWord;
    //NSLog(@"Evaluating %.*s", length, tmpWord);

    return itr->stackDepth;
}

bool loadPrefix(DictionaryIterator *itr, const char *restrict prefix, const int length) {
    resetIterator(itr);

    int index = prefix[0] - 'a' + 1;
    int node = itr->mgr->nodeArray[index];
    itr->tmpWord[0] = *prefix++;

    for(int i = 1; i < length; ++i) {
        assert(node & CHILD_INDEX_BIT_MASK);

        char letterIndex = *prefix++;
        itr->tmpWord[i] = letterIndex;

        //setup the next node
        for(index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT; letterIndex != (itr->mgr->nodeArray[index] & LETTER_BIT_MASK); ++index) {
            assert(!(itr->mgr->nodeArray[index] & END_OF_LIST_BIT_MASK));
        }
        assert(letterIndex == (itr->mgr->nodeArray[index] & LETTER_BIT_MASK));
        node = itr->mgr->nodeArray[index];
    }
    itr->prefixLength = length;
    itr->stackDepth = length;

    dictStack *item = &(itr->stack[length]);
    item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
    item->node = itr->mgr->nodeArray[item->index];
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
                item->node = itr->mgr->nodeArray[++item->index];
                goto LOOP_END2;
            }
        }
        return 0;
    }
LOOP_END2:;

    bool eow;
    int node = item->node;
    do {
        eow = node & END_OF_WORD_BIT_MASK;

        //store the letter and go down
        itr->tmpWord[itr->stackDepth++] = node & LETTER_BIT_MASK;

        //setup the next node
        item = &itr->stack[itr->stackDepth];
        item->index = (node & CHILD_INDEX_BIT_MASK) >> CHILD_BIT_SHIFT;
        item->node = node = itr->mgr->nodeArray[item->index];

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

    assert(isValidWord(itr->mgr, outWord, itr->stackDepth));
    return itr->stackDepth;
}

void resetIterator(DictionaryIterator *itr) {
    itr->stack[0].index = 1;
    itr->stack[0].node = itr->mgr->nodeArray[itr->stack[0].index];
    itr->stackDepth = 0;
    itr->prefixLength = 0;
}

void resetIteratorToPrefix(DictionaryIterator *itr) {
    loadPrefix(itr, itr->tmpWord, itr->prefixLength);
}

#pragma mark -  Setup / Teardown

DictionaryManager *createDictManager(char *dictionary) {
    DictionaryManager *ret = malloc(sizeof(DictionaryManager));

    FILE *data = fopen(dictionary, "rb");
    assert(data);

    int numNodes;
	fread(&numNodes, sizeof(int), 1, data);
	ret->nodeArray = (int*)malloc(numNodes * sizeof(int));
	fread(ret->nodeArray, sizeof(int), numNodes, data);
    
    fclose(data);

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
    free(mgr);
}

void freeDictIterator(DictionaryIterator *itr) {
    free(itr);
}