Pod::Spec.new do |s|
  s.name             = 'SwiftOFX'
  s.version          = '0.1.1'
  s.summary          = 'A framework for reading OFX files.'

  s.description      = <<-DESC
SwiftOFX is a framework for reading and making sense of data from Open Finance Exchange (OFX) files,
which contain account, statement, and transaction information from financial institutions.
Most banking institutions can export account information in this file format.
                       DESC

  s.homepage         = 'https://github.com/altece/SwiftOFX'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'Steven Brunwasser'
  s.source           = { :git => 'https://github.com/altece/SwiftOFX.git', :tag => "v#{s.version.to_s}" }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Source/**/*.swift'
  s.dependency 'Reggie'
end
