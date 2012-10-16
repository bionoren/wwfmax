//
//  main.m
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Board.h"

//anecdotally, ~2.5% of the shipped dictionary is unplayable, mostly because the words are too long for the board, but also because there aren't enough of the required letters and because some words can't be broken down into sufficiently small subwords

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        assert(sizeof(int) == 4);
        assert(HASH(11, 3) == 59); //3,11
        Letter hash = HASH(15, 'z');
        assert(X_FROM_HASH(hash) == 15);
        assert((char)Y_FROM_HASH(hash) == 'z');
        
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        Board *board = [[Board alloc] init];
        
        int numWords = 173101;
        char *words = calloc(numWords * BOARD_LENGTH, sizeof(char));
        int *wordLengths = calloc(numWords, sizeof(int));
        FILE *wordFile = fopen("dict.txt", "r");
        char buffer[40];
        if(wordFile) {
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
        [board solve:words lengths:wordLengths count:numWords];
        free(words);
        free(wordLengths);
    }
    return 0;
}