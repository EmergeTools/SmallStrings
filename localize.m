#include <Foundation/Foundation.h>

@interface LocalizationResult : NSObject

@property (nonatomic) NSSet<NSString *> *keySet;
@property (nonatomic) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *languageCodeToLocalizationsMap;

@end

@implementation LocalizationResult

@end

@interface LocalizationHelper: NSObject {}

+ (LocalizationResult *)readLocalizableStringsJSONMapPath:(NSString *)readLocalizableStringsJSONMapPath;
+ (void)writeLanguageMaps:(LocalizationResult *)result sortedKeySetArray:(NSArray<NSString *> *)sortedKeySetArray valuesJsonLzfseOutputMap:(NSDictionary<NSString *, NSString *> *)valuesJsonLzfseOutputMap compressToolPath:(NSString *)compressToolPath;
+ (void)writeCompressedData:(NSData *)data outputPath:(NSString *)outputPath compressToolPath:(NSString *)compressToolPath;

@end

@implementation LocalizationHelper

+ (LocalizationResult *)readLocalizableStringsJSONMapPath:(NSString *)readLocalizableStringsJSONMapPath {
    NSData *fileData = [NSData dataWithContentsOfFile:readLocalizableStringsJSONMapPath options:0 error:nil];
    NSDictionary<NSString *, NSString *> *jsonDictionary = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *langJsonMap = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *keySet = [NSMutableSet set];
    [jsonDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        NSString *lang = key;
        NSString *putilsLocalizableStringsFile = value;
        NSDictionary<NSString *, NSString *> *localizationValuesMap = [LocalizationHelper createLocalizationValuesMapping:putilsLocalizableStringsFile];
        [keySet addObjectsFromArray:localizationValuesMap.allKeys];
        langJsonMap[lang] = localizationValuesMap;
    }];
    LocalizationResult *result = [[LocalizationResult alloc] init];
    result.keySet = keySet;
    result.languageCodeToLocalizationsMap = langJsonMap;
    return result;
}

+ (NSDictionary<NSString *, NSString *> *)createLocalizationValuesMapping:(NSString *)putilsLocalizableStringsFile {
    return [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:putilsLocalizableStringsFile options:0 error:nil] options:0 error:nil];
}

+ (void)writeLanguageMaps:(LocalizationResult *)result sortedKeySetArray:(NSArray<NSString *> *)sortedKeySetArray valuesJsonLzfseOutputMap:(NSDictionary<NSString *, NSString *> *)valuesJsonLzfseOutputMap compressToolPath:(NSString *)compressToolPath {
    [result.languageCodeToLocalizationsMap enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        NSString *lang = key;
        NSDictionary<NSString *, NSString *> *localizationValuesMap = value;
        NSMutableArray<NSString *> *sortedValues = [NSMutableArray array];
        for (NSString *key in sortedKeySetArray) {
            NSString *value = localizationValuesMap[key];
            if (value) {
                [sortedValues addObject:value];
            }
        }
        NSString *outputPath = valuesJsonLzfseOutputMap[lang];
        [LocalizationHelper writeCompressedData:[NSJSONSerialization dataWithJSONObject:sortedValues options:0 error:nil] outputPath:outputPath compressToolPath:compressToolPath];
    }];
}

+ (void)writeCompressedData:(NSData *)data outputPath:(NSString *)outputPath compressToolPath:(NSString *)compressToolPath {
    NSURL *outputPathURL = [NSURL fileURLWithPath: outputPath];
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:outputPathURL.lastPathComponent];
    [data writeToURL:[NSURL fileURLWithPath: tempFilePath] atomically:YES];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = compressToolPath;
    task.arguments = @[tempFilePath, outputPath];
    [task launch];
    [task waitUntilExit];
    [[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
}

@end

int main(int argc, char *argv[]) {
    if (argc != 5) {
        return 1;
    }
    NSString *compressToolPath = @(argv[1]);
    NSString *localizableStringsJSONMapPath = @(argv[2]);
    NSString *keysJsonLzfseOutputPath = @(argv[3]);
    NSString *valuesJsonLzfseOutputMapPath = @(argv[4]);
    LocalizationResult *result = [LocalizationHelper readLocalizableStringsJSONMapPath:localizableStringsJSONMapPath];
    NSArray<NSString *> *sortedLanguageKeys = [result.keySet.allObjects sortedArrayUsingSelector:@selector(compare:)];
    [LocalizationHelper writeCompressedData:[NSJSONSerialization dataWithJSONObject:sortedLanguageKeys options:0 error:nil] outputPath:keysJsonLzfseOutputPath compressToolPath:compressToolPath];
    NSData *valuesJsonLzfseOutputMapPathData = [NSData dataWithContentsOfFile:valuesJsonLzfseOutputMapPath options:0 error:nil];
    [LocalizationHelper writeLanguageMaps:result sortedKeySetArray:sortedLanguageKeys valuesJsonLzfseOutputMap:[NSJSONSerialization JSONObjectWithData:valuesJsonLzfseOutputMapPathData options:0 error:nil] compressToolPath:compressToolPath];
    return 0;
}
