load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_application",
    "ios_unit_test",
)

objc_library(
    name = "Sources",
    srcs = [
        "App.m",
        "AppDelegate.m",
        "main.m",
    ],
    hdrs = [
        "App.h",
        "AppDelegate.h",
    ],
    data = [
        "//Example/Localization:localize_test",
    ],
    deps = [
        "//:SSTSmallStrings",
    ],
)

objc_library(
    name = "app_test_lib",
    testonly = True,
    srcs = [
        "AppTest.m",
    ],
    deps = [
        ":Sources",
    ],
)

ios_unit_test(
    name = "app_test",
    minimum_os_version = "16.0",
    deps = [
        ":app_test_lib",
    ],
)

ios_application(
    name = "LocalizationExampleApp",
    bundle_id = "com.example.localization-example",
    families = [
        "iphone",
    ],
    infoplists = [":Info.plist"],
    minimum_os_version = "16.0",
    deps = [":Sources"],
)
