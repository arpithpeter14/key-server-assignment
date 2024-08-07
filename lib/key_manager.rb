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

      @keys.each do |key, expiry|
        next if @blocked_keys.include?(key)
        @blocked_keys[key] = now + 60 
        return key
      end

      return nil
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
    @blocked_keys.each do |key, expiry|
      if expiry < now
        @keys[key] = now + 300
        @blocked_keys.delete(key)
      end
    end
  end

  def invalid_key(key)
    return key.nil? || key.strip.empty?
  end
end
