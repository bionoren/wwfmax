//
//  Subword.h
//  wwfmax
//
//  Created by Bion Oren on 10/5/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Subword : NSObject

@property (nonatomic, strong) NSString *word;
//relative to word start, not board 0
@property (nonatomic) int start;
@property (nonatomic) int end;

+(Subword*)subwordWithWord:(NSString*)word start:(int)start end:(int)end;

@end