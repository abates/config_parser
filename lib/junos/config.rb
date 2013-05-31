require 'pp'
require 'junos/interfaces'
require 'junos/security'
require 'junos/applications'

module Junos
  class Config < Parser::ConfigNode
    class Groups < Parser::ConfigNode
      tag "[^:]+", :class => Junos::Config
    end

    tag "security", :class => Security
    tag "applications", :class => Applications
    tag "groups", :class => Groups
    tag "interfaces", :class => Interfaces
  end
end
