Pod::Spec.new do |s|
  s.name             = 'SmallStrings'
  s.version          = '0.1.0'
  s.summary          = 'A minifier for localized .strings files'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = 'Emerge Tools'
  s.source = {:git => 'https://github.com/EmergeTools/SmallStrings'}
  s.homepage = 'https://www.emergetools.com/'

  ios_deployment_target = '11.0'

  s.source_files = [
    'Source/*.{m,h}',
  ]

  s.preserve_paths = [
    'compress',
  ]

  # Ensure the run script and upload-symbols are callable via
  s.prepare_command = <<-PREPARE_COMMAND_END
    clang -O3 compress.m -framework Foundation -lcompression -o compress
  PREPARE_COMMAND_END

  s.libraries = 'compression'
end
