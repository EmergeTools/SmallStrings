![Emerge Tools rounded](https://user-images.githubusercontent.com/6634452/205205728-19b3376a-e99a-4a74-916b-0519deeff08b.png)

# SmallStrings | Reduce localized .strings file sizes by 80%
#### Maintained by [Emerge Tools](https://emergetools.com?utm_source=smallstrings) 

> 🧪 **Note**: This repo is meant as a proof-of-concept on how to reduce localization size. Adjustments may be needed for your specific project.

### How does it work

- Convert .strings files (of the form App.app/\*.lproj/Localizable.strings only) into a minified form
- Eliminate key duplication ([read more about the strategy](https://eisel.me/localization)), this typically reduces the size by about 50%
- Keep small files in a compressed form on disk, using LZFSE, to reduce the size further
- Replace the original language.lproj/Localizable.strings with placeholders that have one key-value pair each. This shows Apple that the same languages are still supported, so that it can pick the correct one based on the user's settings.
- Use the iOS library that replaces `NSLocalizedString` with a new version, `SSTStringForKey` that fetches values for keys from this minified format.

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

- Add `Source/SSTSmallStrings.{h,m}` to your project.
- Create a `compress` binary via `clang -O3 compress.m -framework Foundation -lcompression -o compress` and put the executable in the same directory as `localize.{rb,sh}`.
- Add a build step with `cd /path/to/SmallStrings && ./localize.sh ${CODESIGNING_FOLDER_PATH} ${DERIVED_FILES_DIR}/SmallStrings.cache`.
- Lastly, replace all usages of `NSLocalizedString(key, comment)` with `SSTStringForKey(key)`.
