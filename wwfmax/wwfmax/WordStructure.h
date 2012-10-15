//
//  WordStructure.h
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordStructure : NSObject {
    @public
    Letter _letters[NUM_LETTERS_TURN];
    int _numLetters;
    char *_word;
    int _length;
    Subword _subwords[BOARD_LENGTH];
    int _numSubwords;
}

+(WordStructure*)wordAsLetters:(char*)word length:(int)length;
-(id)initWithWord:(char*)word length:(int)length;

-(NSArray*)validateSubwords:(Subword*)subwords length:(int)numSubwords;

@end