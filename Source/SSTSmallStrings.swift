import Foundation
import Compression

fileprivate func SSTDecompressedDataForFile(_ file: NSURL!) -> NSData {
    // The file format is: |-- 8 bytes for length of uncompressed data --|-- compressed LZFSE data --|
    let compressedData = try! NSData(contentsOf: file as URL, options: .mappedIfSafe)
    
    return withExtendedLifetime(compressedData) {
        let buffer = compressedData.bytes.assumingMemoryBound(to: UInt8.self)
        // Each compressed file is prefixed by a uint64_t indicating the size, in order to know how big a buffer to create
        var outSize: Int = 0
        memcpy(&outSize, buffer, MemoryLayout.stride(ofValue: outSize))
        let outBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: outSize)
        // Although doing this compression may seem time-consuming, in reality it seems to only take a small fraction of overall time for this whole process
        let actualSize: size_t = compression_decode_buffer(
            outBuffer, outSize, buffer.advanced(by: MemoryLayout.stride(ofValue: outSize)),
            compressedData.length - MemoryLayout.stride(ofValue: outSize), nil, COMPRESSION_LZFSE)
        
        return NSData(bytesNoCopy: outBuffer, length: actualSize, freeWhenDone: true)
    }
}

fileprivate func SSTJsonForName(_ name: NSString) -> Any {
    let compressedFile = Bundle.main.url(forResource: name as String, withExtension: nil, subdirectory: "localization")
    let data = SSTDecompressedDataForFile(compressedFile as NSURL?)
    return try! JSONSerialization.jsonObject(with: data as Data, options: [])
}

fileprivate func SSTCreateKeyToString() -> Dictionary<NSString, NSString> {
    // Note that the preferred list does seem to at least include the development region as a fallback if there aren't
    // any other languages
    guard let bestLocalization = Bundle.main.preferredLocalizations.first
                              ?? Bundle.main.developmentLocalization else {
        return [:]
    }
    
    let valuesPath = NSString(format: "%@.values.json.lzfse", bestLocalization)
    let values = SSTJsonForName(valuesPath) as! Array<AnyObject>
    
    let keys = SSTJsonForName("keys.json.lzsfe") as! Array<NSString>
    
    var keyToString = Dictionary<NSString, NSString>(minimumCapacity: keys.count)
    let count = keys.count
    for i in 0..<count {
        let value = values[i]
        guard value !== kCFNull as NSNull? else {
            continue
        }
        let key = keys[i]
        keyToString[key] = value as? NSString
    }
    return keyToString // Avoid -copy to be a bit faster
}

fileprivate class _sKeyToString { }
fileprivate var sKeyToString: Dictionary<NSString, NSString>!

public func SSTStringForKey(_ key: NSString) -> NSString {
    objc_sync_enter(_sKeyToString.self)
    if sKeyToString == nil {
        sKeyToString = SSTCreateKeyToString()
    }
    objc_sync_exit(_sKeyToString.self)
    
    // Haven't tested with CFBundleAllowMixedLocalizations set to YES, although it seems like that'd be handled by the
    // NSLocalizedString fallback
    
    return sKeyToString[key] ?? NSLocalizedString(key as String, comment: "") as NSString
}
