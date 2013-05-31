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
class JunosTest < Test::Unit::TestCase
  test "groups are applied properly" do
    config = get_config()
    assert_equal "1500", config['interfaces']['em0']['mtu'].tags[0]
    assert_equal nil, config['interfaces']['em1']['mtu']
  end

  test "groups are applied with wildcards" do
    config = get_config()
    assert_equal "count", config['security']['policies']['policy-set']['untrust']['trust']['policy']['policy1']['then'].tags[1]
    assert_equal "count", config['security']['policies']['policy-set']['trust']['untrust']['policy']['policy2']['then'].tags[1]
  end

  test "policy-sets have source and destination zone" do
    config = get_config()
    assert_equal "untrust", config['security']['policies']['policy-set']['untrust']['trust'].from_zone_name
    assert_equal "trust", config['security']['policies']['policy-set']['untrust']['trust'].to_zone_name
  end

  test "address-set inclusion lookup" do
    config = get_config()
    assert(config['security']['zones']['security-zone']['trust']['address-book']['address-set']['TRUST-SET1'].include?("192.168.1.1"))
    assert(config['security']['zones']['security-zone']['trust']['address-book']['address-set']['TRUST-SET1'].include?("192.168.1.2"))
    assert(config['security']['zones']['security-zone']['trust']['address-book']['address-set']['TRUST-SET1'].include?("192.168.3.128"))
    assert(!config['security']['zones']['security-zone']['trust']['address-book']['address-set']['TRUST-SET1'].include?("192.168.4.1"))
  end

  def get_config
    return Junos::Parser.parse_file(File.dirname(__FILE__) + "/configs/junos_srx.cfg")
  end
end
