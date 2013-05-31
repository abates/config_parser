require 'parser/config_node'

module Junos
  class Protocol
    attr_reader :protocol
    attr_reader :destination_port

    def initialize protocol, destination_port=nil
      @protocol = protocol
      @destination_port = destination_port
    end

    def to_s
      if (destination_port)
        return "#{protocol}/#{destination_port}"
      else
        return "#{protocol}"
      end
    end
  end

  class TcpUdpTerm < Parser::ConfigNode
    attr_reader :protocol
    attr_reader :destination_port

    def path= path
      super(path)
      @name = path[1]
      @protocol = path[3]
      @destination_port = path[5]
    end

    def to_s
      return "#{@protocol}/#{@destination_port}"
    end
  end


  class IcmpTerm < Parser::ConfigNode
    def protocol
      'icmp'
    end

    def path= path
      super(path)
      @protocol = 'icmp'
      @type = path[5]
    end

    def to_s
      if (@type.nil?)
        return 'icmp'
      else
        return "icmp/#{@type}"
      end
    end
  end

  class Application < Parser::ConfigNode
    tag "term:([^:]+):protocol:[^:]+:destination-port:[^:]+", :class => TcpUdpTerm, :name => 'term'
    tag "term:([^:]+):protocol:icmp:icmp-type:[^:]+", :class => IcmpTerm, :name => 'term'
    tag "term:([^:]+):protocol:icmp", :class => IcmpTerm, :name => 'term'

    def path= path
      @name = path[1]
    end

    def protocols
      values = []

      if (self['protocol'])
        protocol = self['protocol'].keys[0]
        destination_port = nil
        if (self['destination-port'])
          destination_port = self['destination-port'].keys[0]
        end
        values.push(Protocol.new(protocol, destination_port))
      elsif (self['term'])
        self['term'].each do |name, term|
          values.push(term)
        end
      else
        raise "Don't know how to parse #{@config.keys.inspect}"
      end
      return values
    end
  end

  class ApplicationSet < Parser::ConfigNode
    def initialize name, base, parent
      name = name.split(/:/)
      super(name[1], base, parent)
    end
  end

  class Applications < Parser::ConfigNode
    tag "application-set:([^:]+)", :class => ApplicationSet, :name => 'application-set'
    tag "application:([^:]+)", :class => Application, :name => 'application'

    def protocols application
      values = []
      if (application == 'any')
        values.push('any')
      elsif (application =~ /junos-/)
        values.push(application)
      elsif (self['application'][application])
        values.push(*self['application'][application].protocols)
      elsif (self['application-set'][application])
        self['application-set'][application]['application'].each do |name, config|
          values.push(*protocols(name))
        end
      end
      return values
    end
  end
end
