require 'parser/config_node'
require 'ip_parser'

module Junos
  class Address < Parser::ConfigNode
    def path= path
      super(path)
      @address = path[2]
    end

    def include? ip
      ip = IPAddr.new(ip) unless (ip.is_a?(IPAddr))
      if (self['wildcard-address'])
        STDERR.puts "Wildcard addresses not supported in include?"
        return false
      elsif (self['dns-name'])
        STDERR.puts "DNS Names not supported in include?"
        return false
      end
      myip = IPAddr.new(@address)
      return myip.contains?(ip)
    end

    def to_s
      if (@address.nil?)
        if (self['wildcard-address'])
          return self['wildcard-address'].tags[0]
        elsif (self['dns-name'])
          return self['dns-name'].tags[0]
        end
      end
      return @address
    end
  end

  class AddressSet < Parser::ConfigNode
    def include? ip
      ip = IPAddr.new(ip) unless (ip.is_a?(IPAddr))
      self['address'].each do |name, address|
        address = parent.parent['address'][name]
        return true if (address.include?(ip))
      end
      return false
    end
  end

  class AddressBook < Parser::ConfigNode
    tag "address-set:([^:]+)", :class => AddressSet, :name => 'address-set'
    tag "address:([^:]+):[^:]+", :class => Address, :name => 'address'
    tag "address:([^:]+)", :class => Address, :name => 'address'

    def lookup address
      if (address == 'any')
        return 'any'
      elsif (self['address'][address])
        return self['address'][address]
      elsif (self['address-set'][address])
        values = []
        self['address-set'][address]['address'].each do |name, config|
          values.push(*lookup(name))
        end
        return values
      else
        say("WARNING: address #{address} is not defined in zone #{parent.name}", [:red])
      end
      return nil
    end
  end

  class SecurityZone < Parser::ConfigNode
    tag "address-book", :class => AddressBook
  end

  class Policy < Parser::ConfigNode
    def source_address_names
      @source_address_names ||= address_names('source-address')
      return @source_address_names
    end

    def source_addresses
      if (@source_addresses.nil?)
        @source_addresses = resolve_addresses(parent.parent.from_zone, source_address_names)
      end
      return @source_addresses
    end

    def destination_address_names
      @destination_address_names ||= address_names('destination-address')
      return @destination_address_names
    end

    def destination_addresses
      if (@destination_addresses.nil?)
        @destination_addresses = resolve_addresses(parent.parent.to_zone, destination_address_names)
      end
      return @destination_addresses
    end

    def protocols
      if (@protocols.nil?)
        if (self['match'])
          @protocols = resolve_protocols(self['match']['application'])
        else
          @protocols = []
        end
      end
      return @protocols
    end

    def actions
      self['then'].tags
    end

    def resolve_protocols applications
      values = []
      applications.each do |name, config|
        values.push(*base['applications'].protocols(name))
      end
      return values
    end

    def address_names type
      address_names = []
      if (self['match'] && self['match'][type])
        address_names = self['match'][type].collect { |name, config| name }
      end
      return address_names
    end

    def resolve_addresses zone, addresses
      values = []
      addresses.each do |name, config|
        values.push(*zone['address-book'].lookup(name))
      end
      return values
    end
  end

  class PolicySet < Parser::ConfigNode
    tag "policy:([^:]+)", :class => Policy, :name => 'policy'
    attr_reader :from_zone_name
    attr_reader :to_zone_name

    def path= path
      super(path)
      @from_zone_name = path[1]
      @to_zone_name = path[3]
    end

    def from_zone
      base['security']['zones']['security-zone'][@from_zone_name]
    end

    def to_zone
      base['security']['zones']['security-zone'][@to_zone_name]
    end
  end

  class Policies < Parser::ConfigNode
    tag "from-zone:([^:]+):to-zone:([^:]+)", :class => PolicySet, :name => 'policy-set'
  end

  class Zones < Parser::ConfigNode
    tag "security-zone:([^:]+)", :class => SecurityZone, :name => 'security-zone'
  end

  class Security < Parser::ConfigNode
    tag "policies", :class => Policies
    tag "zones", :class => Zones

    def each_policy from_zone=nil, to_zone=nil, &block
      self['policies']['policy-set'].each do |from_zone_name, policy_set|
        if (from_zone.nil? || from_zone == from_zone_name)
          policy_set.each do |to_zone_name, policies|
            if (to_zone.nil? || to_zone == to_zone_name)
              policies['policy'].each do |policy_name, policy|
                block.call(from_zone_name, to_zone_name, policy['policy']) unless (block.nil?)
              end
            end
          end
        end
      end
      return
    end
  end
end
