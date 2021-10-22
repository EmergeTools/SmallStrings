guard CommandLine.argc == 3 else {
    exit(1)
}

let inFile = CommandLine.arguments[1] as NSString
let outFile = CommandLine.arguments[2] as NSString
let data = try? NSData(contentsOfFile: inFile as String, options: .mappedIfSafe)
guard let data = data else {
    exit(1)
}

let outBufferLength = data.length + MemoryLayout<Int>.stride + 500 * 1024
let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outBufferLength)
let outLength = compression_encode_buffer(
    outBuffer.advanced(by: MemoryLayout<Int>.stride), outBufferLength - MemoryLayout<Int>.stride,
    data.bytes.assumingMemoryBound(to: UInt8.self), data.length, nil, COMPRESSION_LZFSE)
guard outLength > 0 else {
    NSLog("Error occurred: either during compression, or because resulting file is much larger than original file")
    exit(1)
}

var inLength = data.length
memcpy(outBuffer, &inLength, MemoryLayout<Int>.stride)
let outData = NSData(bytesNoCopy: outBuffer, length: outLength + MemoryLayout<Int>.stride, freeWhenDone: true)
try! outData.write(toFile: outFile as String, options: .atomic)
exit(0)
