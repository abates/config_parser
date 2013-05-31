require 'parser/config_node'

module Junos
  class InterfaceUnit < Parser::ConfigNode
  end

  class Interface < Parser::ConfigNode
    tag 'unit:(\d+)', :class => InterfaceUnit, :name => 'unit'
  end

  class Interfaces < Parser::ConfigNode
    tag "[^:]+", :class => Interface
    def [] name
      if (name =~ /^([^\.]+)\.([^\.]+)$/)
        return self[$1]['unit'][$2]
      else
        return super(name)
      end
    end
  end
end

