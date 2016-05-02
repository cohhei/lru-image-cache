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
      return nil unless @images.key?(url)

      # replace the image in the end of hash for LRU sort
      existing_image = @images[url]
      @images.delete url
      @images[url] = existing_image
    end

    def write url
      return unless remote_file_exists?(url)

      # If the image don't exists in the hash, open file
      # If the image exists in the hash, replace in the end of hash
      @images[url] = open url, "rb" if read(url).nil?

      # close and delete the oldest image file
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
      @images.key? url
    end

    def count
      @images.length
    end

    def size
      @images.inject(0) { |size, image| size + image.size }
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
