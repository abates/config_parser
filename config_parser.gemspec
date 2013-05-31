Gem::Specification.new do |s|
  s.name        = 'config_parser'
  s.version     = '0.1'
  s.date        = '2013-02-15'
  s.summary     = 'Basic Device Configuration Parser'
  s.description = 'The config parser is a simple interface to write parsers for text configs in order to better report and manipulate config files.  The original intent is to parse config files for network infrastructure devices (routers, swtitches, etc).  A basic parser for Juniper OS (JunOS) is included.'
  s.authors     = ['Andrew Bates']
  s.email       = 'abates@omeganetserv.com'
  s.files       = Dir.glob("lib/**/*")
  s.homepage    = 'https://github.com/abates/'
end
