#
# Be sure to run `pod lib lint MHSConnector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MHSConnector'
  s.version          = '1.0.3'
  s.summary          = 'MHSConnector组件'

  s.description      = '组件间通讯工具组件'

  s.homepage         = 'https://github.com/Mihuashi/MHSConnector.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liuliu' => '1172436954@qq.com' }
  s.source           = { :git => 'https://github.com/Mihuashi/MHSConnector.git', :tag => s.version.to_s }

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
