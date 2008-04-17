require 'test/unit'
RAILS_ENV = "test"
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'RMagick'
require 'acts_as_image_active_record_extensions'
require 'test/mock_model'
require 'fileutils'

class ActsAsImageTest < Test::Unit::TestCase
  
  def test_image_create_success
    File.open(File.join(File.dirname(__FILE__), 'tpb.jpg')) do |f|
      image = MockModel.new
      image.file = f
      assert image.valid?
      image.sizes.keys.each do |size|
        assert File.exists?(image.save_path_with_filename(size))
      end
    end
  ensure
    delete_files
  end
  
  def test_image_create_failure_because_of_missing_file
    image = MockModel.new
    assert !image.valid?
    image.sizes.keys.each do |size|
      assert !File.exists?(image.save_path_with_filename(size))
    end
  end
  
  def test_custom_sizes
    File.open(File.join(File.dirname(__FILE__), 'tpb.jpg')) do |f|
      image = MockModel.new
      image.file = f
      image.sizes = {:foo => '100x100!', :bar => '<50x50'}
      assert image.valid?
      ['foo', 'bar'].each do |size|
        assert File.exists?(image.save_path_with_filename(size))
      end
    end
  ensure
    delete_files
  end
  
  
  def delete_files
    Dir.entries(File.join(File.dirname(__FILE__), 'images')).reject{|f|
      f =~ /^\.+$/
    }.each do |f|
      FileUtils.rm_f(File.join(File.dirname(__FILE__), 'images', f))
    end
  end
  
end
