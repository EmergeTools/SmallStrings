def _localize_impl(ctx):
    localized_strings = {}
    lzfse_output_files = {}
    placeholder_files = []
    target_name_prefix = ""
    if ctx.attr.target_name:
        target_name_prefix = ctx.attr.target_name + "."
    for src in ctx.files.srcs:
        locale = src.dirname.split("/")[-1].split(".")[0]
        localized_strings[locale] = _create_plutil_json_file(ctx, src, locale)
        lzfse_output_files[locale] = ctx.actions.declare_file(
            "{target_name_prefix}{locale}.values.json.lzfse".format(target_name_prefix = target_name_prefix, locale = locale),
        )
        placeholder_files.append(_create_placeholder_file(ctx, src))
    localized_strings_json_file = ctx.actions.declare_file(
        "localized_strings.json",
    )
    ctx.actions.write(
        localized_strings_json_file,
        json.encode(_stringify_file_dict(localized_strings)),
    )
    lzfse_output_files_json_file = ctx.actions.declare_file(
        "lzfse_output_files.json",
    )
    ctx.actions.write(
        lzfse_output_files_json_file,
        json.encode(_stringify_file_dict(lzfse_output_files)),
    )
    keys_json_lzfse_file = ctx.actions.declare_file(
        "{target_name_prefix}keys.json.lzfse".format(target_name_prefix = target_name_prefix),
    )
    args = ctx.actions.args()
    args.add_all([
        ctx.executable._compress_tool,
        localized_strings_json_file,
        keys_json_lzfse_file,
        lzfse_output_files_json_file,
    ])
    ctx.actions.run(
        outputs = lzfse_output_files.values() + [keys_json_lzfse_file],
        inputs = [localized_strings_json_file, lzfse_output_files_json_file] + localized_strings.values(),
        tools = [ctx.executable._compress_tool],
        executable = ctx.executable._localize_tool,
        arguments = [args],
        mnemonic = "SmallStringsLocalize",
    )
    return DefaultInfo(
        files = depset(lzfse_output_files.values() + [keys_json_lzfse_file] + placeholder_files),
    )

def _create_placeholder_file(ctx, src):
    output = ctx.actions.declare_file(src.dirname + "/" + ctx.attr.target_name + src.basename)
    ctx.actions.write(
        output,
        "\"placeholder\" = \"_\";\n",
    )
    return output

def _create_plutil_json_file(ctx, src, locale):
    output = ctx.actions.declare_file("{basename}.{locale}.json".format(
        basename = src.basename,
        locale = locale,
    ))
    args = ctx.actions.args()
    args.add_all([
        "-convert",
        "json",
        "-o",
        output,
        src,
    ])
    ctx.actions.run_shell(
        outputs = [output],
        inputs = [src],
        command = "plutil $@",
        arguments = [args],
        mnemonic = "PlutilJson",
    )
    return output

def _stringify_file_dict(dict):
    result = {}
    for key, value in dict.items():
        result[key] = value.path
    return result

localize = rule(
    implementation = _localize_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".strings"]),
        "target_name": attr.string(
            doc = "A string to key the localization artifacts by, this is optional since non-static builds do not require for assets to have unique name in the final bundle",
        ),
        "_localize_tool": attr.label(
            default = Label("@SmallStrings//:localize"),
            executable = True,
            cfg = "exec",
        ),
        "_compress_tool": attr.label(
            default = Label("@SmallStrings//:compress"),
            executable = True,
            cfg = "exec",
        ),
    },
)
