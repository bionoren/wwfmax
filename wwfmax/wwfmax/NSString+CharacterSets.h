//
//  NSString+CharacterSets.h
//  wwfmax
//
//  Created by Bion Oren on 10/3/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CharacterSets)

-(NSSet*)characterSetsAtX:(int)x y:(int)y;

@end