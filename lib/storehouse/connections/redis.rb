require 'redis'

module Storehouse
  module Connections
    class Redis

      def initialize(spec)
        @spec     = spec || {}
        @redis    = ::Redis.new(@spec)
      end

      def read(path)
        @redis.hgetall(path)
      end

      def write(path, hash)
        @redis.multi do
          @redis.hmset(path, *hash.to_a.flatten)
          @redis.expire(path, backup_expiration)
        end
      end

      def delete(path)
        object = read(path)
        @redis.del(path)
        object
      end

      def expire(path)
        @redis.hset(path, 'expires_at', Time.now.to_i.to_s)
      end

      def clean!(namespace = nil)
        now = Time.now.to_i
        @redis.keys("#{namespace}*").each do |key|
          vals = read(key)
          if vals['expires_at'].to_i < now
            delete(key)
          else
            expire(key)
          end
        end
      end

      def clear!(namespace = nil)
        @redis.keys("#{namespace}*").each do |key|
          @redis.del(key)
        end
      end

      protected

      def backup_expiration
        known_timeout = (Storehouse.spec['timeouts'] || {})['key_expiration']
        if known_timeout
          known_timeout * 2
        else
          3600 * 24 * 14
        end
      end


    end
  end
end