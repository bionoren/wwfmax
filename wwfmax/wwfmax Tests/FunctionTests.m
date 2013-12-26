//
//  BoardTests.m
//  wwfmax
//
//  Created by Bion Oren on 12/23/13.
//  Copyright (c) 2013 Llama Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "functions.h"
#import "DictionaryFunctions.h"

@interface FunctionTests : XCTestCase

@property (nonatomic, assign) Dictionaries *dicts;

@end

@implementation FunctionTests

- (void)setUp {
    [super setUp];

    self.dicts = loadDicts(DICTIONARY_TEST);
}

- (void)tearDown {
    free(_dicts);

    [super tearDown];
}

-(void)testPrescore {
}

-(void)testScoreLettersWithPrescore {
}

-(void)testValidate {
}

-(void)testPlayable {
}

-(void)testWordAsLetters {
}

-(void)testValidateLetters {
}

-(void)testSubwordsAtLocation {
}

@end