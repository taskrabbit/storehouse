require 'aws-sdk'

module Storehouse
  module Adapter
    class S3 < Base

      def initialize(options = {})
        super
        @s3_options = options[:client] || {}
        @bucket_name = options[:bucket] || ['_page_cache', Storehouse.config.scope].compact.join('_')
      end

      protected

      def read(path)
        object = bucket.objects[path]
        object.exists? ? object.read : nil
      rescue AWS::S3::Errors::Forbidden
        nil
      end

      def write(path, content, options = {})
        object = bucket.objects[path]
        object.write(content)
      end

      def delete(path)
        object = bucket.objects[path]
        object.delete
      rescue AWS::S3::Errors::Forbidden
      end

      def clear!
        bucket.clear!
      end

      def bucket
        @bucket ||= begin
          s3 = AWS::S3.new(@s3_options)
          bucket = s3.buckets[@bucket_name]
          s3.buckets.create(@bucket_name) unless bucket.exists?
          bucket
        end
      end
      
      def scoped_key(path)
        path.start_with?('/') ? path[1..-1] : path
      end

    end
  end
end