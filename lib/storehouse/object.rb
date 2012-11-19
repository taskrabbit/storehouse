require 'json'
require 'active_support/json'
require 'active_support/core_ext/object/to_json'

module Storehouse
  class Object

    attr_accessor :path, :content, :headers, :status, :expires_at, :created_at

    def initialize(options = {})
      options.each do |k,v|
        self.send("#{k}=", v) if self.respond_to?("#{k}=")
      end
      self.created_at ||= Time.now.to_i
    end

    def blank?
      self.content.blank?
    end

    def expired?
      return false if self.expires_at.to_i == 0
      self.expires_at.to_i < Time.now.to_i
    end

    def rack_response
      return nil if self.blank?
      [self.status, self.headers, [self.content]]
    end

    def status
      (@status || 200).to_i
    end

    def headers
      @headers = JSON.parse(@headers) if @headers.is_a?(String)
      @headers
    end

    def to_h
      {
        'content' => self.content.to_s,
        'headers' => self.headers.to_json,
        'status' => self.status.to_s,
        'expires_at' => self.expires_at.try(:to_s),
        'created_at' => self.created_at.try(:to_s)
      }
    end

  end
end