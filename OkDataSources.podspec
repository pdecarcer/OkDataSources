#
#  Be sure to run `pod spec lint OkDataSources.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "OkDataSources"
  s.version      = "1.4.0"
  s.summary      = "Wrappers for iOS TableView and CollectionView DataSources to simplify its api at a minimum. Also it has a cool PagerView and SlidingTabs!."

  s.homepage     = "https://github.com/pdecarcer/OkDataSources"
  s.license = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Pablo de Carcer" => "pdecarcer@gmail.com" }
  s.source           = { :git => "https://github.com/pdecarcer/OkDataSources.git", :tag => s.version.to_s }
  s.social_media_url   = "https://github.com/pdecarcer"

  s.ios.deployment_target = '11.0'
  s.requires_arc = true
  s.swift_version = "5.0"

  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files = 'Library/*.swift'
  end

  s.subspec "RxSwift" do |ss|
    ss.source_files = "Library/RxSwift/*.swift"
    ss.dependency "OkDataSources/Core"
    ss.dependency "RxSwift", "5.0"
  end
  
end
