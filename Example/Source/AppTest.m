#import "Example/Source/App.h"
#import <XCTest/XCTest.h>

@interface AppTest : XCTestCase
@end

@implementation AppTest

- (void)testLocalization {
    XCTAssertTrue([@"en_value1" isEqual:[App fetchLocalizationValueForKey:@"string1"]]);
    XCTAssertTrue([@"does_not_exist" isEqual:[App fetchLocalizationValueForKey:@"does_not_exist"]]);
}

@end
