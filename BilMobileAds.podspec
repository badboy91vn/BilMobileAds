Pod::Spec.new do |spec|

  spec.name         = "BilMobileAds"
  spec.version      = "1.0.0"
  spec.summary      = "Summary of BilMobileAds."
  spec.description  = "Description of BilMobileAds."
  spec.homepage     = "https://github.com/badboy91vn/BilMobileAds"
  
  spec.license      = "MIT"
  spec.author       = { "badboy91vn" => "bad.boy91vn@yahoo.com" }
  spec.platform     = :ios, "9.0"
  
  spec.swift_version = '5.0'
  spec.source        = { :git => "https://github.com/badboy91vn/BilMobileAds.git", :tag => "#{spec.version}" }
  spec.source_files  = "BilMobileAds/**/*"

  spec.static_framework = false
  spec.dependency "PrebidMobile", '1.5.0'
  spec.dependency "Google-Mobile-Ads-SDK", '7.60'

end
