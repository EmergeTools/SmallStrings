#!/usr/bin/env ruby

require 'json'
require 'set'
require 'tempfile'

def sh(cmd)
  out = `#{cmd}`
  raise unless $?.success?
  out
end

bundle_dir = ARGV[0]

Dir.chdir(bundle_dir)

keys_set = Set.new
lang_to_map = {}
Dir["*.lproj/Localizable.strings"].each do |strings_file|
  json = sh("plutil -convert json -o - #{strings_file}")
  lang = strings_file.match(/(.*)\.lproj/)[1]
  map = JSON.parse(json)
  lang_to_map[lang] = map
  keys_set += map.keys
end

keys = keys_set.to_a
keys.sort!

out_dir = "#{bundle_dir}/localization"

`rm -r #{out_dir} 2> /dev/null`

sh("mkdir #{out_dir}")

def write_compressed(out, str)
  Tempfile.create('localization_values') do |file|
    file.write(str)
    file.close
    sh("/Users/meisel/Library/Developer/Xcode/DerivedData/buildo-dwqiyznkrgywrwdeidhbstleyeug/Build/Products/Debug/buildo #{file.path} #{out}")
    # sh("/Users/meisel/projects/buildo/compress #{file.path} #{out}")
  end
end

write_compressed("#{out_dir}/keys.json.lzfse", keys.to_json)

lang_to_map.each do |lang, map|
  values = keys.map { |key| map[key] }
  puts "#{out_dir}/#{lang}.values.json.lzfse"
  write_compressed("#{out_dir}/#{lang}.values.json.lzfse", values.to_json)
end
