#####
# = LICENSE
#
# Copyright 2012 Andrew Bates Licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

require 'test_helper'
require 'pp'

#####
#
#
class ParserTest < Test::Unit::TestCase
  test "split line returns expected tokens" do
    class TestParser < Parser::Base
      def tokens
        split_line("token1 token2 token3")
      end
    end
    parser = TestParser.new
    assert_equal ["token1", "token2", "token3"], parser.tokens
  end

  test "split line with quoted strings returns expected tokens" do
    class TestParser < Parser::Base
      def tokens
        split_line("token1 \"token2 token3\" token4")
      end
    end
    parser = TestParser.new
    assert_equal ["token1", "\"token2 token3\"", "token4"], parser.tokens
  end

  test "multilevel tags get add_ method created" do
    class TestChildNode < Parser::ConfigNode
    end

    class TestRootNode < Parser::ConfigNode
      tag 'children:([^:]+):children:([^:]+)', :class => TestChildNode, :name => 'children', :multilevel => true
    end

    class TestParser1 < Parser::Base
      attr_reader :config

      def initialize
        @config = TestRootNode.create_root
        build_path(@config, ['children', 'name1', 'children', 'name2'])
      end
    end

    p = TestParser1.new
    assert_not_nil p.config['children']
    assert_equal Parser::ConfigNode,  p.config['children'].class
    assert_not_nil p.config['children']['name1']
    assert_equal Parser::ConfigNode,  p.config['children']['name1'].class
    assert_not_nil p.config['children']['name1']['name2']
    assert_equal TestChildNode, p.config['children']['name1']['name2'].class
  end
end
