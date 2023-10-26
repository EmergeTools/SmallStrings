load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_unit_test",
)

objc_library(
    name = "module",
    srcs = ["Module.m"],
    hdrs = ["Module.h"],
    data = [
        "//Example/Source/Module/Localization:localizations",
    ],
    deps = [
        "//:SSTSmallStrings",
    ],
)

objc_library(
    name = "module_test_lib",
    testonly = True,
    srcs = ["ModuleTest.m"],
    deps = [
        ":module",
    ],
)

ios_unit_test(
    name = "module_test",
    minimum_os_version = "16.0",
    deps = [
        ":module_test_lib",
    ],
)
