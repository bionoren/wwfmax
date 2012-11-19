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

#define NUM_THREADS 1

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        assert(sizeof(short) >= 2);
        assert(HASH(11, 3) == 59); //3,11
        Letter hash = HASH(BOARD_LENGTH, 'z');
        assert(X_FROM_HASH(hash) == BOARD_LENGTH);
        assert((char)Y_FROM_HASH(hash) == 'z');
        
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        
        int numWords = 173101;
        char *words = calloc(numWords * BOARD_LENGTH, sizeof(char));
        int *wordLengths = calloc(numWords, sizeof(int));
        int *prescores = calloc(numWords, sizeof(int));
        //for each letter, for each board position, a list of pointers to words which can be anchored by that letter at that board position
        //first element of the list is the list length
        
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
                    assert(i < numWords);
                    word += BOARD_LENGTH * sizeof(char);
                }
            }
            numWords = i - 1;
        }
        
        NSLog(@"evaluating %d words", numWords);
        
        const WordInfo info = {.words = words, .numWords = numWords, .lengths = wordLengths, .prescores = prescores};
        
        dispatch_group_t dispatchGroup = dispatch_group_create();
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                for(int i = nextWord(numWords); i >= 0; i = nextWord(numWords)) {
                    char *word = &(words[i * BOARD_LENGTH]);
                    const int length = wordLengths[i];
                    
                    if(!playable(word, length, &info)) {
                        words[i * BOARD_LENGTH] = 0;
                        wordLengths[i] = 0;
                        continue;
                    }
                    
                    prescores[i] = prescoreWord(word, length);
                }
            });
        }
        dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
        
        resetWords();
        
        __block Solution sol;
        sol.maxScore = 0;
        NSLock *lock = [[NSLock alloc] init];
        for(int i = 0; i < NUM_THREADS; ++i) {
            dispatch_group_async(dispatchGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                Board *board = [[Board alloc] init];
                Solution temp = [board solve:&info];
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
        free(prescores);
    }
    return 0;
}