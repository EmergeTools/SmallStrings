#import "SSTSmallStrings.h"
#include <Foundation/Foundation.h>
#import <compression.h>

static NSDictionary <NSString *, NSString *> *sKeyToString = nil;

NSData * SSTDecompressedDataForFile(NSURL *file)
{
    // The file format is: |-- 8 bytes for length of uncompressed data --|-- compressed LZFSE data --|
    NS_VALID_UNTIL_END_OF_SCOPE NSData *compressedData = [NSData dataWithContentsOfURL:file options:NSDataReadingMappedIfSafe error:nil];
    uint8_t *buffer = (uint8_t *)compressedData.bytes;
    // Each compressed file is prefixed by a uint64_t indicating the size, in order to know how big a buffer to create
    uint64_t outSize = 0;
    memcpy(&outSize, buffer, sizeof(outSize));
    uint8_t *outBuffer = (uint8_t *)malloc(outSize);
    // Although doing this compression may seem time-consuming, in reality it seems to only take a small fraction of overall time for this whole process
    size_t actualSize = compression_decode_buffer(outBuffer, outSize, buffer + sizeof(outSize), compressedData.length - sizeof(outSize), NULL, COMPRESSION_LZFSE);
    return [NSData dataWithBytesNoCopy:outBuffer length:actualSize freeWhenDone:YES];
}

id SSTJsonForName(NSString *name, NSBundle *bundle, NSString *subdirectory)
{
    NSURL *compressedFile = [bundle URLForResource:name withExtension:nil subdirectory:subdirectory];
    NSData *data = SSTDecompressedDataForFile(compressedFile);
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

NSDictionary <NSString *, NSString *> *SSTCreateKeyToString(NSBundle *bundle, NSString *subdirectory, NSString *targetName)
{
    // Note that the preferred list does seem to at least include the development region as a fallback if there aren't
    // any other languages
    NSString *bestLocalization = [[bundle preferredLocalizations] firstObject] ?: [bundle developmentLocalization];
    if (!bestLocalization) {
        return @{};
    }
    NSString *targetNamePrefix = @"";
    if (targetName) {
        targetNamePrefix = [NSString stringWithFormat:@"%@.", targetName];
    }
    NSString *valuesPath = [NSString stringWithFormat:@"%@%@.values.json.lzfse", targetNamePrefix, bestLocalization];
    NSArray <id> *values = SSTJsonForName(valuesPath, bundle, subdirectory);

    NSArray <NSString *> *keys = SSTJsonForName([NSString stringWithFormat:@"%@keys.json.lzfse", targetNamePrefix], bundle, subdirectory);

    NSMutableDictionary <NSString *, NSString *> *keyToString = [NSMutableDictionary dictionaryWithCapacity:keys.count];
    NSInteger count = keys.count;
    for (NSInteger i = 0; i < count; i++) {
        id value = values[i];
        if (value == [NSNull null]) {
            continue;
        }
        NSString *key = keys[i];
        keyToString[key] = value;
    }
    return keyToString; // Avoid -copy to be a bit faster
}

NSString *SSTStringForKeyWithBundleAndSubdirectoryAndTargetName(NSString *key, NSBundle *bundle, NSString *subdirectory, NSString *targetName) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKeyToString = SSTCreateKeyToString(bundle, subdirectory, targetName);
    });
    // Haven't tested with CFBundleAllowMixedLocalizations set to YES, although it seems like that'd be handled by the
    // NSLocalizedString fallback
    return sKeyToString[key] ?: NSLocalizedString(key, @"");
}

NSString *SSTStringForKeyWithBundleAndSubdirectory(NSString *key, NSBundle *bundle, NSString *subdirectory)
{
    return SSTStringForKeyWithBundleAndSubdirectoryAndTargetName(key, bundle, subdirectory, nil);
}

NSString *SSTStringForKeyWithBundle(NSString *key, NSBundle *bundle)
{
    return SSTStringForKeyWithBundleAndSubdirectoryAndTargetName(key, bundle, @"localization", nil);
}

NSString *SSTStringForKey(NSString *key)
{
    return SSTStringForKeyWithBundle(key, [NSBundle mainBundle]);
}
