require 'riak'

module Storehouse
  module Connections
    class Riak

      def initialize(spec)
        @spec           = spec || {}
        @bucket_name    = spec.delete('bucket') || 'page_cache'
        @bucket         = ::Riak::Client.new(@spec).bucket(@bucket_name)
      end

      def read(path)
        object = begin
          @bucket.get(path)
        rescue Exception => e
          if e.message =~ /404/
            nil
          else
            raise e
          end
        end

        return {} unless riak_object?(object)

        expires_at = value_from_index(object, 'expires_at_int')
        created_at = value_from_index(object, 'created_at_int')

        data = object.data
        data.merge!('expires_at' => expires_at, 'created_at' => created_at)

        data
      end

      def write(path, hash)
          
        object = @bucket.get_or_new(path)

        return nil unless riak_object?(object)

        object.content_type = 'application/json'
        object.data = hash

        created_at = hash.delete('created_at').to_i
        expires_at = hash.delete('expires_at').to_i

        set_index(object, 'created_at_int', created_at)
        set_index(object, 'expires_at_int', expires_at)

        object.store
      end

      def delete(path)
        hash = read(path)
        @bucket.delete(path)
        hash
      end

      def expire(path)
        hash = read(path)
        hash['expires_at'] = Time.now.to_i
        write(path, hash)
      end

      def clean!(namespace = nil)
        chunked do |key|
          object = read(key)
          if object.expired?
            delete(key)
          else
            expire(key)
          end
        end
      end

      def clear!(namespace = nil)
        chunked do |key|
          delete(key)
        end
      end


      protected

      def chunked
        t = Time.now.to_i - 60*24*60*60 # 2 months ago
        t0 = Time.now.to_i 

        clearing_delta = 24*60*60 # one day
        cnt = 0

        # chunked sets of keys based on created at timestamp
        begin

          t1 = t0 - clearing_delta
          t1 = [t1, t].max

          cnt = 0
          @bucket.get_index('created_at_int', t0.to_i...t1.to_i).each do |k|
            yield k
            cnt += 1
          end

          t0 -= clearing_delta

        end while(t < t0 && cnt > 0)
      end

      def set_index(object, name, value)
        object.indexes[name] = Set.new([value])
      end


      def value_from_index(object, name)
        val = object.indexes[name]
        val.respond_to?(:first) ? val.first : val # might come back as a Set
      end

      def riak_object?(object)
        object.is_a?(::Riak::RObject)
      end


    end
  end
end