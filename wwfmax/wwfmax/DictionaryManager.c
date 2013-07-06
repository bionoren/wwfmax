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

// Use the first two CWG arrays to return a boolean value indicating if "TheCandidate" word is in the lexicon.
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

int nextWord_threadsafe(DictionaryIterator *itr, char *restrict outWord) {
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
    assert(BOARD_LENGTH + 1 == 16);
    for(int i = 0; i < 4; i++) {
        ((int*restrict)outWord)[i] = ((int*restrict)itr->tmpWord)[i];
    }
    //NSLog(@"Evaluating %.*s", length, tmpWord);

#if DEBUG
    assert(isValidWord(itr->mgr, outWord, itr->stackDepth));
#endif
    int ret = itr->stackDepth;
    OSSpinLockUnlock(&itr->lock);
    return ret;
}

int nextWord(DictionaryIterator *itr, char *restrict outWord) {
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
    outWord = itr->tmpWord;
    //NSLog(@"Evaluating %.*s", length, tmpWord);

#if DEBUG
    assert(isValidWord(itr->mgr, outWord, itr->stackDepth));
#endif
    return itr->stackDepth;
}

void resetIterator(DictionaryIterator *itr) {
#ifdef DEBUG
    printf("Reseting dictionary iterator...\n");
#endif
    itr->stack[0].index = 1;
    itr->stack[0].node = itr->mgr->nodeArray[itr->stack[0].index];
    itr->stackDepth = 0;
}

DictionaryManager *createDictManager(char *dictionary) {
    DictionaryManager *ret = malloc(sizeof(DictionaryManager));

    // Array size variables.
    int numNodes;
    
    // Read the CWG graph, from the "GRAPH_DATA" file, into the global arrays.
    FILE *data = fopen(dictionary, "rb");
    assert(data);

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