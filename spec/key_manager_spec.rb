require 'rspec'
require_relative '../lib/key_manager'

describe KeyManager do
  let(:key_manager) { KeyManager.new }

  describe '#generate_key' do
    it 'generates a key' do
      key = key_manager.generate_key
      expect(key).not_to be_nil
      expect(key_manager.keys).to include(key)
      expect(key_manager.unblocked_keys).to include(key)
      expiry = key_manager.keys[key]
      expect(expiry).to be_within(1).of(Time.now + 300)
    end
  end

  describe '#get_available_key' do
    it 'returns an available key and blocks it' do
      key = key_manager.generate_key
      available_key = key_manager.get_available_key
      expect(available_key).to eq(key)
      expect(key_manager.blocked_keys).to include(key)
      expect(key_manager.unblocked_keys).not_to include(key)
    end

    it 'returns nil if there is no key available' do
      expect(key_manager.get_available_key).to be_nil
    end
  end

  describe '#unblock_key' do
    it 'unblocks a blocked key' do
      key = key_manager.generate_key
      key_manager.get_available_key
      key_manager.unblock_key(key)
      expect(key_manager.blocked_keys).not_to include(key)
      expect(key_manager.unblocked_keys).to include(key)
    end

    it 'returns false if the key does not exist' do
      expect(key_manager.unblock_key('not_key')).to be_falsey
    end
  end

  describe '#delete_key' do
    it 'deletes a key' do
      key = key_manager.generate_key
      key_manager.get_available_key
      key_manager.delete_key(key)
      expect(key_manager.keys).not_to include(key)
      expect(key_manager.blocked_keys).not_to include(key)
      expect(key_manager.unblocked_keys).not_to include(key)
    end

    it 'returns false if the key does not exist' do
      expect(key_manager.delete_key('not_key')).to be_falsey
    end
  end

  describe '#keep_alive_key' do
    it 'extends the expiry of a key' do
      key = key_manager.generate_key
      old_expiry = key_manager.keys[key]
      key_manager.keep_alive_key(key)
      new_expiry = key_manager.keys[key]
      expect(new_expiry).to be > old_expiry
    end

    it 'returns false if the key does not exist' do
      expect(key_manager.keep_alive_key('not_key')).to be_falsey
    end
  end

  describe '#clean_expired_keys' do
    it 'removes expired keys' do
      key = key_manager.generate_key
      key_manager.keys[key] = Time.now - 1
      key_manager.clean_expired_keys
      expect(key_manager.keys).not_to include(key)
    end

    it 'removes expired blocked keys' do
      key = key_manager.generate_key
      key_manager.blocked_keys[key] = Time.now - 0.5
      key_manager.clean_expired_keys
      expect(key_manager.unblocked_keys).to include(key)
      expect(key_manager.blocked_keys).not_to include(key)
      expiry = key_manager.keys[key]
      expect(expiry).to be_within(1).of(Time.now + 300)
    end
  end
end
