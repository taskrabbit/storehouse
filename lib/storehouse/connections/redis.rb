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
        @redis.hmset(path, *hash.to_a.flatten)
      end

      def delete(path)
        @redis.del(path)
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
          delete(key)
        end
      end


    end
  end
end