require 'RMagick'
require 'acts_as_image_active_record_extensions'
ActiveRecord::Base.send(:include, FleskPlugins::ActsAsImage::ActiveRecordExtensions)