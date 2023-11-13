#import "Example/Source/Module/Module.h"
#import "Source/SSTSmallStrings.h"

@implementation Module

+ (NSString *)fetchLocalizationValueForKey:(NSString *)key {
    return SSTStringForKeyWithBundleAndSubdirectoryAndTargetName(key, [NSBundle bundleForClass:[self class]], nil, @"example_Source_Module_module");
}

@end
