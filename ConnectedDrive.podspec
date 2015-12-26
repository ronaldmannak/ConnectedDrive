Pod::Spec.new do |s|
  s.name = 'ConnectedDrive'
  s.version = '0.1'
  s.license = 'MIT'
  s.summary = 'Access to BMW\'s ConnectedDrive service for the BMW i3 and i8'
  s.homepage = 'https://github.com/ronaldmannak/ConnectedDrive'
  s.social_media_url = 'http://twitter.com/ronaldmannak'
  s.authors = { 'Ronald Mannak' => 'ronaldmannak@me.com' }

  s.source = { :git => 'https://github.com/ronaldmannak/ConnectedDrive.git', :tag => s.version }
  s.source_files = 'ConnectedDrive/*.swift'
  
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'

  s.dependency 'Alamofire', '~> 3.1'
  s.dependency 'Decodable', '~> 0.3.3'
end