require "lru_image_cache/version"
require 'open-uri'
require 'net/http'

module LruImageCache
  class Cache
    def initialize
      @capacity = 10
      @images = Hash.new
    end

    def read url
      existing_image = @images[url]
      if existing_image
        @images.delete url
        @images[url] = existing_image
      else
        nil
      end
    end

    def write url
      return unless remote_file_exists?(url)
      existing_image = @images[url]
      if existing_image
        @images.delete url
        @images[url] = existing_image
      else
        @images[url] = open url, "rb"
      end

      if @images.length > @capacity
        @images.first.close
        @images.delete_if { |key, value| value == nil }
      end
    end

    def delete
      @images.each do |image|
        image.close
      end
      @images.clear
    end

    def empty?
      @images.empty?
    end

    def exists? url
      @images[url]
    end

    def count
      @images.length
    end

    def size
      size = 0
      @images.each { |image| size += image.size }
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
