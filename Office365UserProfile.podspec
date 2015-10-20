Pod::Spec.new do |s|
  s.name             = "Office365UserProfile"
  s.version          = "0.1.0"
  s.summary          = "iOS library for fetching user info from the Office 365 Unified API"
  s.author           = { "Stephanie Sharp" => "hello@stephsharp.me" }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.public_header_files = 'Office365UserProfile/**/*.h'
  s.source_files = 'Office365UserProfile/**/*'
  
  s.dependency 'ADALiOS', '~> 1.2.1'
end
