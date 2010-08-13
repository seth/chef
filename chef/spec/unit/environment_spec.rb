#
# Author:: Stephen Delano (<stephen@ospcode.com>)
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
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require 'chef/environment'

describe Chef::Environment do
  before(:each) do
    @environment = Chef::Environment.new
  end

  describe "initialize" do
    it "should be a Chef::Environment" do
      @environment.should be_a_kind_of(Chef::Environment)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      @environment.name("production").should == "production"
    end

    it "should return the current name" do
      @environment.name("production")
      @environment.name.should == "production"
    end

    it "should not accept spaces" do
      lambda { @environment.name("production environment") }.should raise_error(ArgumentError)
    end

    it "should not accept anything but strings" do
      lambda { @environment.name(Array.new) }.should raise_error(ArgumentError)
      lambda { @environment.name(Hash.new) }.should raise_error(ArgumentError)
      lambda { @environment.name(2) }.should raise_error(ArgumentError)
    end
  end

  describe "description" do
    it "should let you set the description to a string" do
      @environment.description("this is my test environment").should == "this is my test environment"
    end

    it "should return the correct description" do
      @environment.description("I like running tests")
      @environment.description.should == "I like running tests"
    end

    it "should not accept anything but strings" do
      lambda { @environment.description(Array.new) }.should raise_error(ArgumentError)
      lambda { @environment.description(Hash.new) }.should raise_error(ArgumentError)
      lambda { @environment.description(42) }.should raise_error(ArgumentError)
    end
  end

  describe "cookbook_versions" do
    before(:each) do
      @cookbook_versions = {
        "apt"     => "1.0.0",
        "god"     => "2.0.0",
        "apache2" => "4.2.0"
      }
    end

    it "should let you set the cookbook versions in a hash" do
      @environment.cookbook_versions(@cookbook_versions).should == @cookbook_versions
    end

    it "should return the cookbook versions" do
      @environment.cookbook_versions(@cookbook_versions)
      @environment.cookbook_versions.should == @cookbook_versions
    end

    it "should not accept anything but a hash" do
      lambda { @environment.cookbook_versions("I am a string!") }.should raise_error(ArgumentError)
      lambda { @environment.cookbook_versions(Array.new) }.should raise_error(ArgumentError)
      lambda { @environment.cookbook_versions(42) }.should raise_error(ArgumentError)
    end

    it "should validate the hash" do
      Chef::Environment.should_receive(:validate_cookbook_versions).with(@cookbook_versions).and_return true
      @environment.cookbook_versions(@cookbook_versions)
    end
  end

  describe "to_hash" do
    before(:each) do
      @environment.name("spec")
      @environment.description("Where we run the spec tests")
      @environment.cookbook_versions({:apt => "1.2.3"})
      @hash = @environment.to_hash
    end

    %w{name description cookbook_versions}.each do |t|
      it "should include '#{t}'" do
        @hash[t].should == @environment.send(t.to_sym)
      end
    end

    it "should include 'json_class'" do
      @hash["json_class"].should == "Chef::Environment"
    end

    it "should include 'chef_type'" do
      @hash["chef_type"].should == "environment"
    end
  end

  describe "to_json" do
    before(:each) do
      @environment.name("spec")
      @environment.description("Where we run the spec tests")
      @environment.cookbook_versions({:apt => "1.2.3"})
      @json = @environment.to_json
    end

    %w{name description cookbook_versions}.each do |t|
      it "should include '#{t}'" do
        @json.should =~ /"#{t}":#{Regexp.escape(@environment.send(t.to_sym).to_json)}/
      end
    end

    it "should include 'json_class'" do
      @json.should =~ /"json_class":"Chef::Environment"/
    end

    it "should include 'chef_type'" do
      @json.should =~ /"chef_type":"environment"/
    end
  end

  describe "from_json" do
    before(:each) do
      @data = {
        "name" => "production",
        "description" => "We are productive",
        "cookbook_versions" => {
          "apt" => "1.2.3",
          "god" => "4.2.0",
          "apache2" => "2.0.0"
        },
        "json_class" => "Chef::Environment",
        "chef_type" => "environment"
      }
      @environment = JSON.parse(@data.to_json)
    end

    it "should return a Chef::Environment" do
      @environment.should be_a_kind_of(Chef::Environment)
    end

    %w{name description cookbook_versions}.each do |t|
      it "should match '#{t}'" do
        @environment.send(t.to_sym).should == @data[t]
      end
    end
  end

  describe "self.validate_cookbook_versions" do
    before(:each) do
      @cookbook_versions = {
        "apt"     => "1.0.0",
        "god"     => "2.0.0",
        "apache2" => "4.2.0"
      }
    end

    it "should return true when all versions are strings" do
      Chef::Environment.validate_cookbook_versions(@cookbook_versions).should == true
    end

    it "should return false when anything other than a string is passed as a version" do
      a = @cookbook_versions.dup.merge :number => 2
      Chef::Environment.validate_cookbook_versions(a).should == false

      b = @cookbook_versions.dup.merge :hash => {:foo => 'bar'}
      Chef::Environment.validate_cookbook_versions(b).should == false

      c = @cookbook_versions.dup.merge :array => ['this', 'is', 'a', 'bad', 'version']
      Chef::Environment.validate_cookbook_versions(c).should == false

      d = @cookbook_versions.dup.merge :cookbook_versions => Chef::CookbookVersion.new("meta")
      Chef::Environment.validate_cookbook_versions(d).should == false
    end
  end
end