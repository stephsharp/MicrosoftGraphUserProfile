Pod::Spec.new do |s|
  s.name         = "MicrosoftGraphUserProfile"
  s.version      = "0.2.1"
  s.summary      = "iOS library for fetching user info from the Microsoft Graph API"
  s.homepage     = "https://github.com/stephsharp/MicrosoftGraphUserProfile"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = "Stephanie Sharp"
  s.platform     = :ios, '8.0'
  s.source       = { :git => "https://github.com/stephsharp/MicrosoftGraphUserProfile.git", :tag => "v#{s.version}" }
  s.source_files = 'MicrosoftGraphUserProfile'
  s.public_header_files = [ "MicrosoftGraphUserProfile/MicrosoftGraphUserProfile.h",
                            "MicrosoftGraphUserProfile/MGAuthenticationManager.h", 
                            "MicrosoftGraphUserProfile/MGUserProfileAPIClient.h",
                            "MicrosoftGraphUserProfile/MGUser.h" ]
  s.dependency 'ADALiOS', '~> 1.2'
  s.requires_arc = true
end
