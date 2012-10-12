//
//  WordStructure.h
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Subword.h"

@interface WordStructure : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *parts;

+(WordStructure*)wordAsLetters:(NSString*)word x:(int)x y:(int)y;
-(id)initWithWord:(NSString*)word;

-(void)addSubword:(Subword*)subword;
-(NSArray*)validate;

@end