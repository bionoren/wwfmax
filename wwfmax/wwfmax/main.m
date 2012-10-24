//
//  main.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Board.h"

#define NUM_THREADS 1

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        assert(sizeof(int) == 4);
        assert(HASH(11, 3) == 59); //3,11
        Letter hash = HASH(BOARD_LENGTH, 'z');
        assert(X_FROM_HASH(hash) == BOARD_LENGTH);
        assert((char)Y_FROM_HASH(hash) == 'z');
        
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        
        int numWords = 173101;
        char *words = calloc(numWords * BOARD_LENGTH, sizeof(char));
        int *wordLengths = calloc(numWords, sizeof(int));
        FILE *wordFile = fopen("dict.txt", "r");
        if(wordFile) {
            char buffer[40];
            int i = 0;
            char *word = words;
            while(fgets(buffer, 40, wordFile)) {
                int len = (int)strlen(buffer) - 1;
                if(len <= BOARD_LENGTH) {
                    strncpy(word, buffer, len);
                    wordLengths[i++] = len;
                    word += BOARD_LENGTH * sizeof(char);
                }
            }
            numWords = i - 1;
        }
        NSLog(@"evaluating %d words", numWords);
        dispatch_group_t dispatchGroup = dispatch_group_create();
        __block struct solution sol;
        sol.maxScore = 0;
        NSLock *lock = [[NSLock alloc] init];
        for(int i = 0; i < NUM_THREADS; i++) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                struct solution temp = [board solve:words lengths:wordLengths count:numWords];
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
        
        free(words);
        free(wordLengths);
    }
    return 0;
}