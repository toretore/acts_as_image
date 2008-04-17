
#http://www.bigbold.com/snippets/posts/show/767
ActiveRecord::Base.class_eval do
  alias_method :save, :valid?
  def self.columns() @columns ||= []; end
  
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type, null)
  end
end

class MockModel < ActiveRecord::Base
  
  def self.validates_uniqueness_of(foo)
    nil
  end

  column :content_type, :string
  column :hash_string, :string
  column :original_filename, :string

  acts_as_image
  
  self.image_sizes = {
    :large => '>800x600',
    :medium => '>640x480',
    :small => '>320x240'
  }
  
  self.image_save_path = File.join(File.dirname(__FILE__), 'images')
  
  
  def hash_string
    'abcdef'
  end
  
  
  def generate_hash_string
    'abcdef'
  end
  

end