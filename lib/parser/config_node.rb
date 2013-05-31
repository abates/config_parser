
require 'rubygems'
require 'thor'

class String
  def underscore
    word = split(/::/).last
    word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end

module Parser
  class ConfigNode < Thor::Shell::Color
    attr_accessor :annotation
    attr_accessor :active
    attr_accessor :parent
    attr_accessor :name
    attr_reader :base
    attr_reader :tags

    def self.containers
      @containers ||= []
      return @containers
    end

    def self.tag pattern, options={}
      options[:name] = options[:name] || pattern
      options[:class] ||= ConfigNode
      options[:add_method] ||= "add_#{options[:name].underscore}".to_sym
      options[:pattern] = pattern
      containers.push options
    end

    def self.create_root
      return self.new(nil, nil, nil)
    end

    def path
      @path
    end

    def path= path
      @path = path
    end

    def clone 
      new_node = self.class.new(@name.nil? ? nil : @name.clone, base, nil)
      new_node.active = @active
      new_node.annotation = @annotation.nil? ? '' : @annotation.clone
      @tags.each do |tag|
        new_node[tag] = self[tag].clone
      end
      return new_node
    end

    def initialize name, base = nil, parent = nil
      super()
      @name = name
      @base = base 
      if (base.nil?)
        @base = self
      end
      @parent = parent 

      @container = {}
      @active = true
      @annotation = ''
      @tags = []
    end

    def [] key
      @container[key]
    end

    def []= key, value
      raise "Nil is not a valid key" if (key.nil?)
      raise "Nil is not a valid value" if (value.nil?)
      raise "Can only set a tag once (tag #{key} value #{value})" unless (@container[key].nil?)

      @tags.push(key)
      @container[key] = value
      if (value.respond_to?(:parent=))
        value.parent = self
      end
    end

    def keys
      @container.keys
    end

    def collect &block
      values = []
      each do |tag, config|
        values.push(block.call(tag, config)) unless (block.nil?)
      end
      return values
    end

    def each &block
      @tags.each do |tag|
        block.call(tag, @container[tag]) unless (block.nil?)
      end
    end

    def pattern
      pattern = @name
      if (pattern =~ /^<(.+)>$/)
        pattern = $1
        pattern.gsub!(/\[\!/, '[^')
        pattern.gsub!(/\?/, '.?')
        pattern.gsub!(/\*/, '.*')
      end
      return /^#{pattern}$/
    end

    def absolute_path
      if (@parent.nil?)
        return []
      else
        return Array.new(@parent.absolute_path).push(name)
      end
    end

    def leaf_node?
      @container.size == 0
    end

    def merge destination
      @tags.each do |skey|
        matched = false
        destination.keys.each do |dkey|
          if (skey == dkey || dkey =~ @container[skey].pattern)
            @container[skey].merge(destination[dkey])
            matched = true
          end
        end
        unless (matched)
          raise "#{skey} already set!" unless (destination[skey].nil?)
          destination[skey] = @container[skey].clone
        end
      end
    end

    def match_path path, &block
      path = path.clone
      first = path.shift
      @tags.each do |tag|
        if (first =~ self[tag].pattern)
          if (path.length == 0)
            block.call(tag, @container[tag]) unless (block.nil?)
          else
            @container[tag].match_path(path, &block)
          end
        end
      end
    end

    def all_attributes &block
      each do |name, value|
        block.call(path, value) if (value.leaf_node?)
      end
      each do |name, value|
        value.all_attributes(&block) unless (value.leaf_node?)
      end
    end
  end
end
