#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'chef/version_class'

describe Chef::Version do

  describe "<=>" do

    it "should sort based on the version number" do
      examples = [
                  # smaller, larger
                  ["1.0", "2.0"],
                  ["1.2.3", "1.2.4"],
                  ["1.2.3", "1.3.0"],
                  ["1.2.3", "1.3"],
                  ["1.2.3", "2.1.1"],
                  ["1.2.3", "2.1"],
                  ["1.2", "1.2.4"],
                  ["1.2", "1.3.0"],
                  ["1.2", "1.3"],
                  ["1.2", "2.1.1"],
                  ["1.2", "2.1"]
                 ]
      examples.each do |smaller, larger|
        sm = Chef::Version.new(smaller)
        lg = Chef::Version.new(larger)
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should equate versions 1.2 and 1.2.0" do
      Chef::Version.new("1.2").should == Chef::Version.new("1.2.0")
    end

    it "should equate version 1.04 and 1.4" do
      Chef::Version.new("1.04").should == Chef::Version.new("1.4")
    end

    it "should treat versions as numbers in the right way" do
      Chef::Version.new("2.0").should be < Chef::Version.new("11.0")
    end
  end
  

  describe "when you create a Version" do
    it "should accept valid cookbook versions" do
      good_versions = %w(1.2 1.2.3 1000.80.50000 0.300.25)
      good_versions.each do |v|
        Chef::Version.new v
      end
    end

    it "should raise InvalidCookbookVersion for bad cookbook versions" do
      bad_versions = ["1.2.3.4", "1.2.a4", "1", "a", "1.2 3", "1.2 a",
                      "1 2 3", "1-2-3", "1_2_3", "1.2_3", "1.2-3"]
      the_error = Chef::Exceptions::InvalidCookbookVersion
      bad_versions.each do |v|
        lambda { Chef::Version.new v }.should raise_error(the_error)
      end
    end
  end
end
