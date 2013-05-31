
require 'stringio'
require 'parser/base'
require 'junos/config'

module Junos
  class Parser < Parser::Base
    def self.parse_config config
      return parse_io(StringIO.new(config))
    end

    def self.parse_file filename
      return parse_io(File.open(filename))
    end

    def self.parse_io io
      config = Junos::Config.create_root()
      Junos::Parser.new().parse(io, config)
      return config
    end

    def parse io, config
      @top ||= config
      while (line = io.gets)
        line = line.strip.gsub(/\s*\#.*$/, '')
        active = true

        # Config statements and blocks that are disabled
        # are pre-pended with inactive:
        if (line =~ /^\s*inactive:\s*(.+)/)
          active = false
          line = $1
        end

        # single line annotation
        if (line =~ /^\s*\/\*\s*(.*)\s*\*\/\s*$/)
          annotation = $1
        # multi line annotation
        elsif (line =~ /^\s*\/\*\s*(.*)$/)
          multiline_annotation = true
          annotation = $1
        elsif (multiline_annotation)
          # end of the annotation
          if (line =~ /(.*)\s*\*\/\s*$/)
            annotation += $1
            annotation = annotation.gsub(/[\r\n]+/, ' ').gsub(/\s+/, ' ').strip
            multiline_annotation = false
          # annotation continues
          else
            annotation += line
          end
        # config value
        elsif (line =~ /^\s*(.*)\s*;\s*$/)
          statement = $1.strip
          # handle multi-valued items (items like destination-address [address1 address2 address3];)
          if (statement =~ /^\s*(.+)\s*\[([^\]]+)\]\s*$/)
            path = $1.strip
            split_line($2.strip).each do |value|
              build_path(config, split_line(path).push(value))
            end
          else
            path = split_line(statement)
            build_path(config, path)
          end
        # enter a block
        elsif (line =~ /^\s*(.*)\s*\{\s*$/)
          path = split_line($1.strip)
          new_config = build_path(config, path)
          parse(io, new_config)
          unless (new_config.nil?)
            new_config.annotation = annotation
            new_config.active = active
          end
        # leave a block
        elsif (line.end_with?('}'))
          # import group values
          if (config['apply-groups'])
            config['apply-groups'].each do |name, value|
              next if (name =~ /\$\{/)
              group = @top['groups'][name]
              #STDERR.puts "Applying group #{name}"
              if (group.nil?)
                STDERR.puts "WARNING: Group '#{name}' does not exist!"
                STDERR.puts "WARNING: Config path is #{config.absolute_path.join(':')}"
                STDERR.puts "WARNING: Apply-Group keys are #{config['apply-groups'].keys.inspect}"
              else
                path = config.absolute_path
                group.match_path(path) do |name, value|
                  value.merge(config)
                end
              end
            end
          end
          return config
        end
      end
      return config
    end
  end
end

