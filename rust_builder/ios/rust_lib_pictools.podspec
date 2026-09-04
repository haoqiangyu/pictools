Pod::Spec.new do |s|
  s.name             = 'rust_lib_pictools'
  s.version          = '0.0.1'
  s.summary          = 'Rust image processing library for Pictools.'
  s.description      = 'Builds the Pictools Rust library for iOS through Cargokit.'
  s.homepage         = 'https://github.com/haoqiangyu/pictools'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Pictools' => 'https://github.com/haoqiangyu/pictools' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../rust rust_lib_pictools',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ['${BUILT_PRODUCTS_DIR}/librust_lib_pictools.a'],
  }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/librust_lib_pictools.a -lc++',
  }
end
