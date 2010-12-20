#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2010 Opscode, Inc.
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

require 'openssl'
require 'chef/data_bag_item'
require 'yaml'

# An EncryptedDataBagItem represents a read-only data bag item where
# all values, except for the value associated with the id key, have
# been encrypted.
#
# EncrypedDataBagItem can be used in recipes to decrypt data bag item
# members.
#
# Data bag item values are assumed to have been encrypted using the
# default symmetric encryption provided by Encryptor.encrypt where
# values are converted to YAML prior to encryption.
#
# If the shared secret is not specified at initialization or load,
# then the contents of the file referred to in
# Chef::Config[:encrypted_data_bag_secret] will be used as the
# secret.  The default path is /etc/chef/encrypted_data_bag_secret
#
# EncryptedDataBagItem is intended to provide a means to avoid storing
# data bag items in the clear on the Chef server.  This provides some
# protection against a breach of the Chef server or of Chef server
# backup data.  Because the secret must be stored in the clear on any
# node needing access to an EncryptedDataBagItem, this approach
# provides no protection of data bag items from actors with access to
# such nodes in the infrastructure.
#
class Chef::EncryptedDataBagItem
  DEFAULT_SECRET_FILE = "/etc/chef/encrypted_data_bag_secret"
  ALGORITHM = 'aes-256-cbc'

  def initialize(enc_hash, secret)
    @enc_hash = enc_hash
    @secret = secret
  end

  def [](key)
    value = @enc_hash[key]
    if key == "id"
      value
    else
      klass = Chef::EncryptedDataBagItem
      YAML.load(klass.decrypt_string(value, @secret))
    end
  end

  def []=(key, value)
    raise ArgumentError, "assignment not supported for #{self.class}"
  end

  def self.from_plain_hash(plain_hash, secret)
    klass = Chef::EncryptedDataBagItem
    klass.new(klass.encrypt(plain_hash, secret), secret)
  end

  def self.encrypt(plain_hash, secret)
    klass = Chef::EncryptedDataBagItem
    plain_hash.inject({}) do |h, (key, val)|
      h[key] = if key != "id"
                 klass.encrypt_string(val.to_yaml, secret)
               else
                 val
               end
      h
    end
  end

  def self.load(data_bag, name, secret = nil)
    path = "data/#{data_bag}/#{name}"
    raw_hash = Chef::DataBagItem.load(data_bag, name)
    secret = secret || self.load_secret
    Chef::EncryptedDataBagItem.new(raw_hash, secret)
  end

  def self.encrypt_string(string, key)
    self.cipher(:encrypt, string, key)
  end

  def self.decrypt_string(string, key)
    self.cipher(:decrypt, string, key)
  end

  protected

  def self.load_secret
    path = Chef::Config[:encrypted_data_bag_secret] || DEFAULT_SECRET_FILE
    if !File.exists?(path)
      raise Errno::ENOENT, "file not found '#{path}'"
    end
    secret = IO.read(path)
    if secret.size < 1
      raise ArgumentError, "invalid zero length secret in '#{path}'"
    end
    secret
  end

  def self.cipher(direction, data, key)
    cipher = OpenSSL::Cipher::Cipher.new(ALGORITHM)
    cipher.send(direction)
    cipher.pkcs5_keyivgen(key)
    ans = cipher.update(data)
    ans << cipher.final
    ans
  end
end
