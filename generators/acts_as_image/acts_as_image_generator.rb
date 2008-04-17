class ActsAsImageGenerator < Rails::Generator::NamedBase


  def manifest
    camel_name, under_name, plural_name = args[0] ? inflect_names(args[0]) : ['Image', 'image', 'images']
    
    record do |m|
      case file_name
      
        when 'model'
          m.template 'model.rb', File.join('app', 'models', "#{under_name}.rb"),
            {:assigns => {:name => camel_name}}
          unless options[:skip_migration]
            m.migration_template 'migration.rb', File.join('db', 'migrate'),
              {:migration_file_name => "create_#{plural_name}",
                :assigns => {:class_name => plural_name.camelize, :table_name => plural_name}}
          end
        
        when 'migration'
          m.migration_template 'migration.rb', File.join('db', 'migrate'),
              {:migration_file_name => "create_#{plural_name}",
                :assigns => {:class_name => plural_name.camelize, :table_name => plural_name}}
        
        else
          puts "Could not recognise action \"#{file_name}\"."
      
      end
    end
  end
  
  
  def banner
    "Usage: #{$0} #{spec.name} <action>"
  end
  
  
  protected
  
    def add_options!(opt)
      opt.on('--skip-migration', "Don't create migration when creating model."){|v| options[:skip_migration] = true }
    end


end