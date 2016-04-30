require "test/unit"
require 'open-uri'
require 'lru_image_cache'

class CacheTest < Test::Unit::TestCase
  setup do
    @images_url = [
      "http://dummyimage.com/300x100/000/fff.jpg",
      "http://dummyimage.com/300x200/000/fff.jpg",
      "http://dummyimage.com/300x300/000/fff.jpg",
      "http://dummyimage.com/300x400/000/fff.jpg",
      "http://dummyimage.com/300x500/000/fff.jpg",
      "http://dummyimage.com/600x100/000/fff.jpg",
      "http://dummyimage.com/600x200/000/fff.jpg",
      "http://dummyimage.com/600x300/000/fff.jpg",
      "http://dummyimage.com/600x400/000/fff.jpg",
      "http://dummyimage.com/600x500/000/fff.jpg"
    ]
    @cache = LruImageCache::Cache.new
  end

  sub_test_case 'for empty cache' do
    def test_new_cache_is_empty
      assert @cache.empty?
    end

    def test_invalid_url
      @cache.write "aaaaa"
      assert @cache.empty?
    end
  end

  sub_test_case 'for cache contained 10 images' do
    setup do
      @cache.delete
      @images_url.each { |url| @cache.write url }
    end

    def test_not_empty
      assert @cache.size
    end

    def test_count
      assert_equal @images_url.length, @cache.count
    end

    def test_size
      sum = 0.0
      @images_url.each do |url|
        open url do |f|
          sum += f.size
        end
      end
      assert_equal @cache.size, sum
    end

    def test_read_images
      @images_url.each do |url|
        open url do |f|
          cache_image = @cache.read url
          assert_not_nil cache_image
          assert_equal cache_image.size, f.size
        end
      end
    end

    def test_read_invalid_url
      assert_equal @cache.read("aaaaa"), nil
    end

    def test_valid_url_exists
      @images_url.each do |url|
        assert @cache.exists? url
      end
    end

    def test_invalid_url_exists
      assert_equal @cache.exists?(""), false
    end

    def test_delete
      @cache.delete
      assert @cache.empty?
    end

    def test_remove_oldest_cache
      @cache.read @images_url[0]
      additional_url = "http://dummyimage.com/500x500/111/fff.jpg"
      @cache.write additional_url
      assert_equal @cache.exists?(@images_url[0]), true
      assert_equal @cache.exists?(@images_url[1]), false
    end

    def test_thread_safe
      another_cache = LruImageCache::Cache.new
      @images_url.each { |url| another_cache.write url }
      @cache.delete
      assert @cache.empty?
      assert_equal another_cache.count, @images_url.length
    end
  end
end
