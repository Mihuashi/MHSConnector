#
# Be sure to run `pod lib lint MHSConnector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MHSConnector'
  s.version          = '1.0.1'
  s.summary          = 'A short description of MHSConnector.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'MHSConnector 组件'

  s.homepage         = 'https://github.com/Mihuashi/MHSConnector.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liuliu' => '1172436954@qq.com' }
  s.source           = { :git => 'git@github.com:Mihuashi/MHSConnector.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'
  s.static_framework = true

  s.source_files = 'MHSConnector/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MHSConnector' => ['MHSConnector/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
