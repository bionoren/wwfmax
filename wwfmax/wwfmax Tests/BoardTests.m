//
//  BoardTests.m
//  wwfmax
//
//  Created by Bion Oren on 12/23/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Board-test.h"
#import "DictionaryFunctions.h"

@interface BoardTests : XCTestCase

@property (nonatomic, strong) Board *board;
@property (nonatomic, assign) Dictionaries *dicts;

@end

@implementation BoardTests

- (void)setUp {
    [super setUp];

    self.board = [[Board alloc] init];
    self.dicts = loadDicts(DICTIONARY_TEST);
}

- (void)tearDown {
    free(_dicts);

    [super tearDown];
}

- (void)testPreprocess {
    char *word = "aahed";
}

@end