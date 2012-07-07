require 'aws-sdk'

module Storehouse
  module Adapter
    class S3 < Base

      def initialize(options = {})
        super
        @s3_options = options[:client] || {}
        @bucket_name = options[:bucket] || '_page_cache'
      end

      def read(path)
        object = bucket.objects[end_path(path)]
        object.exists? ? object.read : nil
      rescue AWS::S3::Errors::Forbidden
        nil
      end

      def write(path, content)
        object = bucket.objects[end_path(path)]
        object.write(content)
      end

      def delete(path)
        object = bucket.objects[end_path(path)]
        object.delete
      rescue AWS::S3::Errors::Forbidden
      end

      def clear!
        bucket.clear!
      end

      def bucket
        s3 = AWS::S3.new(@s3_options)
        bucket = s3.buckets[@bucket_name]
        s3.buckets.create(@bucket_name) unless bucket.exists?
        bucket
      end

      def end_path(path)
        path.start_with?('/') ? path[1..-1] : path
      end

    end
  end
end