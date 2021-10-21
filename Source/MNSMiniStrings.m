#import "MNSMiniStrings.h"
#import <compression.h>

@implementation MNSMiniStrings

static NSDictionary <NSString *, NSString *> *sKeyToString = nil;

+ (NSData *)_decompressedDataForFile:(NSURL *)file
{
    // The file format is: |-- 8 bytes for length of uncompressed data --|-- compressed LZFSE data --|
    NS_VALID_UNTIL_END_OF_SCOPE NSData *compressedData = [NSData dataWithContentsOfURL:file options:NSDataReadingMappedIfSafe error:nil];
    uint8_t *buffer = (uint8_t *)compressedData.bytes;
    // Each compressed file is prefixed by a uint64_t indicating the size, in order to know how big a buffer to create
    uint64_t outSize = 0;
    memcpy(&outSize, buffer, sizeof(outSize));
    uint8_t *outBuffer = (uint8_t *)malloc(outSize);
    size_t actualSize = compression_decode_buffer(outBuffer, outSize, buffer + sizeof(outSize), compressedData.length - sizeof(outSize), NULL, COMPRESSION_LZFSE);
    return [NSData dataWithBytesNoCopy:outBuffer length:actualSize freeWhenDone:YES];
}

+ (id)_jsonForName:(NSString *)name
{
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *cacheDirectory = [documentsDirectory URLByAppendingPathComponent:@"emerge-cache/localization"];
    NSURL *cacheFile = [[cacheDirectory URLByAppendingPathComponent:name] URLByDeletingPathExtension]; // Remove .lzfse
    NSData *cacheData = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFile.path]) {
        // Pull the compressed version from the bundle and write out
        [[NSFileManager defaultManager] createDirectoryAtURL:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *compressedFile = [[NSBundle mainBundle] URLForResource:name withExtension:nil subdirectory:@"localization"];
        NSData *cacheData = [self _decompressedDataForFile:compressedFile];
        [cacheData writeToURL:cacheFile atomically:YES];
    } else {
        cacheData = [NSData dataWithContentsOfURL:cacheFile options:NSDataReadingMapped error:nil];
    }
    return [NSJSONSerialization JSONObjectWithData:cacheData options:0 error:nil];
}

+ (NSDictionary <NSString *, NSString *> *)_createKeyToString
{
    // Note that the preferred list does seem to at least include the development region as a fallback if there aren't
    // any other languages
    NSString *bestLocalization = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    if (!bestLocalization) {
        return @{};
    }
    NSString *valuesPath = [NSString stringWithFormat:@"%@.values.json.lzfse", bestLocalization];
    NSArray <id> *values = [self _jsonForName:valuesPath];

    NSArray <NSString *> *keys = [self _jsonForName:@"keys.json.lzfse"];

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

+ (NSString *)stringForKey:(NSString *)key
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKeyToString = [self _createKeyToString];
    });
    // Haven't tested with CFBundleAllowMixedLocalizations set to YES, although it seems like that'd be handled by the
    // NSLocalizedString fallback
    return sKeyToString[key] ?: NSLocalizedString(key, @"");
}

@end
