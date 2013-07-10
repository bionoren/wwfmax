//
//  main.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Board.h"
#import "functions.h"
#import "DictionaryManager.h"
#import "dawg.h"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

int main(int argc, const char * argv[]) {
    @autoreleasepool {
#if DEBUG
        assert(sizeof(short) >= 2);
        assert(HASH(11, 3) == 59); //3,11
        Letter hash = HASH(BOARD_LENGTH, 'z');
        assert(X_FROM_HASH(hash) == BOARD_LENGTH);
        assert((char)Y_FROM_HASH(hash) == 'z');
#endif
        
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        //NOTE: generated datastructures account for approximately 3Mb of storage
        char *dictionary = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dict.txt", 173101, true);
        //cat validDict.txt | rev > dictReversed.txt
        char *dictionaryReversed = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dictReversed.txt", 173101, false);
        char *dictionaryPermuted = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dictPermuted.txt", 952650, false);
        //cat dictPermuted.txt | rev > dictPermutedReversed.txt
        char *dictionaryPermutedReversed = CWGOfDictionaryFile("/Users/bion/projects/objc/wwfmax/dictPermutedReversed.txt", 952650, false);
        
        DictionaryManager *mgr = createDictManager(dictionary);
        Dictionaries dicts;
        dicts.words = createDictIterator(mgr);
        dicts.pwords = createDictManager(dictionaryPermuted);
        dicts.rwords = createDictManager(dictionaryReversed);
        dicts.rpwords = createDictManager(dictionaryPermutedReversed);
        
        __block Solution sol;
        sol.maxScore = 0;
        NSLock *lock = [[NSLock alloc] init];
        dispatch_group_t dispatchGroup = dispatch_group_create();
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                Solution temp = [board solve:dicts];
                if([lock lockBeforeDate:[NSDate distantFuture]]) {
                    if(temp.maxScore > sol.maxScore) {
                        sol = temp;
                    }
                    [lock unlock];
                }
            });
        }
        
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        printSolution(sol);

        freeDictionaries(dicts);
        freeDictManager(mgr);
    }
    return 0;
}