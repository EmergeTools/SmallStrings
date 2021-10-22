#import "SSTSmallStrings.h"
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

id SSTJsonForName(NSString *name)
{
    NSURL *compressedFile = [[NSBundle mainBundle] URLForResource:name withExtension:nil subdirectory:@"localization"];
    NSData *data = SSTDecompressedDataForFile(compressedFile);
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

NSDictionary <NSString *, NSString *> *SSTCreateKeyToString()
{
    // Note that the preferred list does seem to at least include the development region as a fallback if there aren't
    // any other languages
    NSString *bestLocalization = [[[NSBundle mainBundle] preferredLocalizations] firstObject] ?: [[NSBundle mainBundle] developmentLocalization];
    if (!bestLocalization) {
        return @{};
    }
    NSString *valuesPath = [NSString stringWithFormat:@"%@.values.json.lzfse", bestLocalization];
    NSArray <id> *values = SSTJsonForName(valuesPath);

    NSArray <NSString *> *keys = SSTJsonForName(@"keys.json.lzfse");

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

NSString *SSTStringForKey(NSString *key)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKeyToString = SSTCreateKeyToString();
    });
    // Haven't tested with CFBundleAllowMixedLocalizations set to YES, although it seems like that'd be handled by the
    // NSLocalizedString fallback
    return sKeyToString[key] ?: NSLocalizedString(key, @"");
}
