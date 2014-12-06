//
//  RaftelTests.m
//  RaftelTests
//
//  Created by  on 12/6/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "Manga.h"
#import "Mangapanda.h"

@interface RaftelTests : XCTestCase

@end

@implementation RaftelTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParseName {
    NSArray *sources = [self.class sourcesPlist];
    NSDictionary *mangapanda = [sources firstObject];
    NSDictionary *manga = mangapanda[@"manga"];
    NSString *mangaNameRegexPattern = manga[@"name"];
    
    NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.mangapanda.com/103/one-piece.html"]];
    NSString *urlContentString = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    
    Mangapanda *panda = [[Mangapanda alloc] init];
    NSString *name = [panda matchInString:urlContentString pattern:mangaNameRegexPattern];
    XCTAssertEqualObjects(name, @"One Piece");
    
    Manga *mangaObject = [panda mangaWithContentURLString:urlContentString];
    XCTAssertNotNil(mangaObject);
    XCTAssertEqualObjects(mangaObject.name, @"One Piece");
    XCTAssertEqualObjects(mangaObject.source, @"mangapanda");
    XCTAssertEqualObjects(mangaObject.alternateName, @"One Piece");
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

+ (NSArray *)sourcesPlist {
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"sources.plist"]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"sources" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSError *error;
    NSArray *temp = (NSArray *)[NSPropertyListSerialization
                                          propertyListWithData:plistXML options:0 format:&format error:&error];
    
    return temp;
}

@end
