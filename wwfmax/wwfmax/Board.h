//
//  Board.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Board : NSObject

-(void)solve:(char*)words lengths:(int*)wordLengths count:(int)numWords;

@end