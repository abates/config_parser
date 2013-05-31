
require 'parser/config_node'

module Parser
  class Base
    private
      def build_path config, path
        raise "Empty path passed into set_value" if (path.length == 0)
        # See if the parent has a specific class for this path
        match_path = path.join(":")
        match_container = nil
        config.class.containers.each do |container|
          match = /^#{container[:pattern]}$/.match(match_path)
          if (match)
            match_container = container
            match_container[:last_match] = match
            break
          end
        end
        if (match_container.nil?)
          depth = 0
          path.each do |p|
            config[p] ||= ConfigNode.new(p, config.base, config)
            depth += 1
            config = config[p]
          end
        else
          klass = match_container[:class]
          if (config.respond_to?(match_container[:add_method]))
            new_config = klass.new(path.join(':'), config.base, config)
            config.send(match_container[:add_method], new_config)
          elsif (match_container[:last_match].captures.length > 0)
            captures = match_container[:last_match].captures
            config[match_container[:name]] ||= ConfigNode.new(match_container[:name], config.base, config)
            config = config[match_container[:name]]
            top = captures.pop
            captures.each do |capture|
              config[capture] ||= ConfigNode.new(capture, config.base, config)
              config = config[capture]
            end
            new_config = klass.new(top, config.base, config)
            config[top] = new_config
          else
            # TODO: why is this an ||= ?  Need a test for it
            new_config = klass.new(path.join(':'), config.base, config)
            config[new_config.name] ||= new_config
          end
          config = new_config
        end
        config.path = path
        return config
      end

      def split_line line
        return line.split(/\s(?=(?:[^"]|"[^"]*")*$)/)
      end
  end
end

