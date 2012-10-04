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
        NSLog(@"%@", [[[NSFileManager alloc] init] currentDirectoryPath]);
        Board *board = [[Board alloc] init];
        NSError *err = nil;
        NSArray *words = [[NSString stringWithContentsOfFile:@"dict.txt" encoding:NSMacOSRomanStringEncoding error:&err] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        [board solve:words];
    }
    return 0;
}