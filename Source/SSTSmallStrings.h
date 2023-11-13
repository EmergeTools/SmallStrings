#import <Foundation/Foundation.h>

NSString *SSTStringForKey(NSString *key);
NSString *SSTStringForKeyWithBundle(NSString *key, NSBundle *bundle);
NSString *SSTStringForKeyWithBundleAndSubdirectory(NSString *key, NSBundle *bundle, NSString *subdirectory);
NSString *SSTStringForKeyWithBundleAndSubdirectoryAndTargetName(NSString *key, NSBundle *bundle, NSString *subdirectory, NSString *targetName);
