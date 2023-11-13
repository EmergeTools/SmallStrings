#import "Example/Source/App.h"
#import "Source/SSTSmallStrings.h"

@implementation App

+ (NSString *)fetchLocalizationValueForKey:(NSString *)key {
    return SSTStringForKeyWithBundleAndSubdirectoryAndTargetName(key, [NSBundle bundleForClass:[self class]], nil, @"example_Source_app_Sources");
}

@end
