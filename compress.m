//
//  compress.c
//  buildo
//
//  Created by Michael Eisel on 10/20/21.
//

#include <compression.h>
#include <Foundation/Foundation.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        return 1;
    }
    NSString *inFile = @(argv[1]);
    NSString *outFile = @(argv[2]);
    NSData *data = [NSData dataWithContentsOfFile:inFile options:NSDataReadingMappedIfSafe error:nil];
    if (!data) {
        return 1;
    }
    size_t outBufferLength = data.length + sizeof(uint64_t) + 500 * 1024;
    uint8_t *outBuffer = (uint8_t *)malloc(outBufferLength);
    uint64_t outLength = compression_encode_buffer(outBuffer + sizeof(uint64_t), outBufferLength - sizeof(uint64_t), data.bytes, data.length, NULL, COMPRESSION_LZFSE);
    if (outLength == 0) {
        NSLog(@"Error occurred: either during compression, or because resulting file is much larger than original file");
        return 1;
    }
    uint64_t inLength = data.length;
    memcpy(outBuffer, &inLength, sizeof(uint64_t));
    NSData *outData = [NSData dataWithBytesNoCopy:outBuffer length:outLength + sizeof(uint64_t) freeWhenDone:YES];
    [outData writeToFile:outFile atomically:YES];
    return 0;
}
