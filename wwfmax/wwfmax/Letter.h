//
//  Letter.h
//  wwfmax
//
//  Created by Bion Oren on 10/1/12.
//  Copyright (c) 2012 Llama Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Letter : NSObject <NSCopying>

@property (nonatomic) char letter;
@property (nonatomic) unsigned int x;
@property (nonatomic) unsigned int y;

+(Letter*)letterWithCharacter:(char)c x:(int)x y:(int)y;

@end