require 'securerandom'
require 'thread'

class KeyManager
  attr_reader :keys, :blocked_keys

  def initialize
    @keys = {}
    @blocked_keys = {}
    @mutex = Mutex.new
  end

  def generate_key
    key = SecureRandom.hex(16)
    # 5 min expiry
    expiry = Time.now + 300 
    @mutex.synchronize do
      @keys[key] = expiry
    end
    key
  end

  def get_available_key
    @mutex.synchronize do
      now = Time.now
      unblocked_keys = @keys.reject { |key, _| @blocked_keys.key?(key) }

      return nil if unblocked_keys.empty?

      key, _ = unblocked_keys.first
      # block this key for 60 seconds
      @blocked_keys[key] = now + 60 
      key
    end
  end

  def unblock_key(key)
    @mutex.synchronize do
      return false unless @keys.key?(key)
      @blocked_keys.delete(key)
      @keys[key] = Time.now + 300
      true
    end
  end

  def delete_key(key)
    @mutex.synchronize do
      return false unless @keys.key?(key) 
      @keys.delete(key)
      @blocked_keys.delete(key)
      true
    end
  end

  def keep_alive_key(key)
    @mutex.synchronize do
      return false unless @keys.key?(key)
      @keys[key] = Time.now + 300
      true
    end
  end

  def clean_expired_keys
      now = Time.now
      @keys.reject! { |_, expiry| expiry < now }
      @blocked_keys.reject! { |_, expiry| expiry < now }
  end

  def invalid_key(key)
    return key.nil? || key.strip.empty?
  end
end
