require "lru_image_cache/version"
require 'open-uri'
require 'net/http'

module LruImageCache
  class Cache
    def initialize
      @capacity = 10
      @images = Array.new
    end

    def read url
      existing_image = @images.find { |image| image[:url] == url }
      if existing_image
        @images.delete existing_image
        @images << existing_image
        return existing_image[:file]
      end
      return nil
    end

    def write url
      return unless remote_file_exists?(url)
      file = open url, "rb"
      new_image = { url: url, file: file }
      existing_image = @images.find { |image| image[:url] == url }

      if existing_image
        existing_image[:file].close
        @images.delete existing_image
      end

      @images << new_image
      if @images.length > @capacity
        @images.first[:file].close
        @images.shift
      end
    end

    def delete
      @images.each do |image|
        image[:file].close
      end
      @images.clear
    end

    def empty?
      @images.empty?
    end

    def exists? url
      found = @images.find { |image| image[:url] == url }
      !found.nil?
    end

    def count
      @images.length
    end

    def size
      size = 0
      @images.each { |image| size += image[:file].size }
      size
    end

    private
    def remote_file_exists? url
      begin
        url = URI.parse(url)
        Net::HTTP.start(url.host, url.port) do |http|
          return http.head(url.request_uri).code == "200"
        end
      rescue
        false
      end
    end
  end
end
