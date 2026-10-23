Pod::Spec.new do |s|
  s.name             = 'device_display_name'
  s.version          = '0.1.0'
  s.summary          = 'The name a person knows their device by, and the kind of device it is.'
  s.description      = <<-DESC
The name a person knows their device by instead of its hardware code, and the kind of device it is.
                       DESC
  s.homepage         = 'https://github.com/SERDUN/device_display_name'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dmytro Serdun' => 'dmitriiserdun@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'device_display_name/Sources/device_display_name/**/*.swift'
  s.resource_bundles = { 'device_display_name_privacy' => ['device_display_name/Sources/device_display_name/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
