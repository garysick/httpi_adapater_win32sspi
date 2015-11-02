require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'httpi-adapter-win32sspi'
  spec.summary    = 'A HTTPI Adapter the uses Win32SSPI'
  spec.version    = '0.0.1.rc1'
  spec.author     = 'Gary Sick'
  spec.license    = 'MIT'
  spec.email      = 'garys361@gmail.com'
  spec.platform   = Gem::Platform::CURRENT
  spec.required_ruby_version = '>=1.9'
  spec.homepage   = 'https://github.com/garysick/httpi_adapter_win32sspi'
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') || f.include?('Notes.txt') }
  spec.test_files = Dir['test/*.rb']
  spec.has_rdoc   = false

  spec.add_dependency('win32-sspi', '=0.0.1.rc1')
  spec.add_development_dependency('test-unit','~>3.0')
  spec.requirements << "This gem will only work in a Windows Environment"

  spec.description = <<-EOF
    A HTTPI Adapter the uses Win32SSPI library.
    Support the Negotiate protocols.
    See examples for usage.
  EOF
end
