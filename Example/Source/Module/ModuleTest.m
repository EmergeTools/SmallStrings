#import <XCTest/XCTest.h>
#import "Example/Source/Module/Module.h"

@interface ModuleTest : XCTestCase
@end

@implementation ModuleTest

- (void)testLocalization {
    XCTAssertTrue([@"en_module_value1" isEqual:[Module fetchLocalizationValueForKey:@"string1"]]);
    XCTAssertTrue([@"does_not_exist" isEqual:[Module fetchLocalizationValueForKey:@"does_not_exist"]]);
}

@end
