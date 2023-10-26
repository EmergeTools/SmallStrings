load("//:localize.bzl", "localize")

localize(
    name = "localize_test",
    srcs = [
        "en.lproj/Localizable.strings",
        "es.lproj/Localizable.strings",
    ],
    target_name = "example_Source_app_Sources",
    visibility = [
        "//Example/Source:__pkg__",
    ],
)
