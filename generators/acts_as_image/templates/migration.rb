class Create<%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table '<%= table_name %>' do |t|
      t.column :title, :string
      t.column :body, :text
      t.column :original_filename, :string
      t.column :content_type, :string
      t.column :hash_string, :string, :length => 32
      
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down
    drop_table '<%= table_name %>'
  end
end