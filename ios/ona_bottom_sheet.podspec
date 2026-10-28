Pod::Spec.new do |s|
  s.name             = 'ona_bottom_sheet'
  s.version          = '0.3.0'
  s.summary          = "Apple's Liquid Glass surface for Ona bottom sheets."
  s.description      = <<-DESC
The native iOS side of ona_bottom_sheet: a platform view that draws Apple's Liquid Glass (iOS 26 and later)
behind a sheet's Flutter content.
                       DESC
  s.homepage         = 'https://github.com/ONA-AI-Labs/ona-bottom-sheet'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ona AI Labs' => 'https://onavoice.ai' }
  s.source           = { :path => '.' }
  s.source_files     = 'ona_bottom_sheet/Sources/ona_bottom_sheet/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.9'
  s.resource_bundles = { 'ona_bottom_sheet_privacy' => ['ona_bottom_sheet/Sources/ona_bottom_sheet/PrivacyInfo.xcprivacy'] }
end
