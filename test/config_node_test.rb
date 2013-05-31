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
class ConfigNodeTest < Test::Unit::TestCase
  test "creating root node has no parent" do
    config_node = Parser::ConfigNode.create_root
    assert_equal nil, config_node.parent
  end

  test "creating root node has base set to self" do
    config_node = Parser::ConfigNode.create_root
    assert_equal config_node, config_node.base
  end

  test "assigning node to parent reset's node's parent" do
    root_node = Parser::ConfigNode.create_root
    config_node = Parser::ConfigNode.create_root
    root_node['child'] = config_node
    assert_equal root_node, config_node.parent
  end

  test "config node only allows one instance of a tag name" do
    root_node = Parser::ConfigNode.create_root
    root_node['tag'] = 'test value'
    assert_raise RuntimeError do
      root_node['tag'] = 'new test value'
    end
  end

  test "test cloning a node copies all the attributes" do
    root_node = Parser::ConfigNode.create_root
    (0...5).each do |i|
      config_node = Parser::ConfigNode.new('test name', root_node, root_node)
      root_node["test#{i}"] = config_node
    end
    new_root = root_node.clone

    assert_not_equal root_node, new_root
    assert_equal root_node.tags, new_root.tags
    (0...5).each do |i|
      assert_not_equal root_node["test#{i}"], new_root["test#{i}"]
      root_node["test#{i}"].instance_variables.each do |v|
        old_val = root_node["test#{i}"].instance_variable_get(v)
        new_val = new_root["test#{i}"].instance_variable_get(v)

        if (old_val.is_a?(TrueClass) || old_val.is_a?(FalseClass) || old_val.is_a?(Fixnum))
          assert_equal old_val, new_val
        elsif (v == '@base')
          assert_equal old_val.object_id, new_val.object_id, "Base should always refer to the same object, but it did not"
        else
          assert_not_equal old_val.object_id, new_val.object_id, "Value #{v} (#{old_val.class}) was not copied"
        end
      end
      assert_equal root_node["test#{i}"].name, new_root["test#{i}"].name
    end
  end
end
