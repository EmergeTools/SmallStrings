# SmallStrings
## Reducing localized .strings file sizes by 80%

### How it works

The library consists of a build-time minification step, and an iOS library:
- The minification tool converts the .strings files (of the form App.app/\*.lproj/Localizable.strings only) into a minified form. First, this tool eliminates key duplication by following the strategy from https://eisel.me/localization. This reduces the size by roughly 50%. Then, it keeps all these small files in a compressed form on disk, using LZFSE, reducing the size further. It also replaces the original language.lproj/Localizable.strings with placeholders that have one key-value pair each. This shows Apple that the same languages are still supported, so that it can pick the correct one based on the user's settings.
- An iOS library that replaces `NSLocalizedString` with a new version, `SSTStringForKey` that fetches values for keys from this minified format.

### Usage

#### Cocoapods

Add this to your Podfile:
```
pod 'SmallStrings'
```

Then add a Run Script build phase after the "Copy bundle resources" phase:
```
cd ${PODS_ROOT}/SmallStrings && ./localize.sh ${CODESIGNING_FOLDER_PATH} ${DERIVED_FILES_DIR}/SmallStrings.cache
```

Lastly, replace all usages of `NSLocalizedString(key, comment)` with `SSTStringForKey(key)`.

#### Manual

Add `Source/SSTSmallStrings.{h,m}` to your project. Create a `compress` binary via `clang -O3 compress.m -framework Foundation -lcompression -o compress` and put the executable in the same directory as `localize.{rb,sh}`. Add a build step with `cd /path/to/SmallStrings && ./localize.sh ${CODESIGNING_FOLDER_PATH} ${DERIVED_FILES_DIR}/SmallStrings.cache`. Lastly, replace all usages of `NSLocalizedString(key, comment)` with `SSTStringForKey(key)`.
