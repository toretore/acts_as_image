module FleskPlugins#:nodoc:
  module ActsAsImage#:nodoc:
  
    #This module extends ActiveRecord.
    #
    #<tt>ClassMethods</tt> are added to all model classes.
    #<tt>SingletonMethods</tt> are added to all model classes containing <tt>acts_as_image</tt>.
    #<tt>InstanceMethods</tt> are added to all models of classes containing <tt>acts_as_image</tt>.
    module ActiveRecordExtensions#
  
      def self.included(base)#:nodoc:
        base.send(:extend, ClassMethods)
      end
  
      module ClassMethods
      
      
        def acts_as_image
          include InstanceMethods
          extend SingletonMethods
          @image_sizes ||= HashWithIndifferentAccess.new
          @image_save_path ||= File.join(RAILS_ROOT, 'public', 'images', 'uploads')
          @image_read_path ||= ['images', 'uploads'].join('/')
          attr_accessor :file
          validates_uniqueness_of :hash_string
          before_validation :generate_hash_string, :process_image
          after_destroy :delete_files
        end
        
        
      end
      
      
      #Methods in this module are added to the model class
      module SingletonMethods
        
        
        #Returns a hash which holds the default sizes for the
        #images. The keys are names for the various sizes, and will
        #be used as file names. The values are ImageMagick geometry
        #strings. See http://www.simplesystems.org/RMagick/doc/imusage.html#geometry
        #for more information on how they work. If the value is an array,
        #the first element holds the geometry string while the second is
        #a symbol specifying what method to use for resizing the image at this size.
        #If the symbol is :scale, the X:Y ratio will be changed as necessary
        #to fit the entire image. If it is :crop, any parts of the original that
        #don't fit with the new ratio will be clipped.
        #
        #:crop requires RMagick version 1.10.0 or later.
        def image_sizes
          @image_sizes
        end
        
        
        #Inserts a whole new hash into <tt>image_sizes</tt>. If you
        #only want to change or add a specific size, do something
        #like Image.image_sizes[:ginormous] = '6000x4000!'
        def image_sizes=(sizes)
          @image_sizes = sizes
        end
        
        
        #This is the path that will be presented to the browser
        def image_read_path
          @image_read_path
        end
        
        
        def image_read_path=(path)
          @image_read_path = path
        end
        
        
        #This is the path on the server where images will
        #be saved. The image's own path() will be added to it.
        def image_save_path
          @image_save_path
        end
        
        
        def image_save_path=(path)
          @image_save_path = path
        end
      
      
      end
      
      
      #Methods in this module are added as instance methods to the model class.
      #
      #About paths: There's two different paths, the <tt>read_path</tt> and the <tt>save_path</tt>.
      #The former is the public path, by which the image will be reachable from the outside world,
      #and the latter is the server path where Rails can write or read the files. Each image also
      #has its own sub-path in order to prevent having all the files in one directory, so the complete
      #path to an image would be something like
      #
      #<tt>images/uploads/1/2/34567890abcdef/large.jpg</tt> (read_path_with_filename('large'))
      #<tt>RAILS_ROOT/public/images/uploads/1/2/34567890abcdef/large.jpg</tt> (save_path_with_filename('large'))
      #
      #The <tt>url</tt> method adds a / to <tt>read_path_with_filename</tt>.
      module InstanceMethods
      
        
        #Use this to get a URL to the image with the specific size
        #that can be read by the browser
        def url(size = nil, ext = nil)
          '/'+read_path_with_filename(size, ext)
        end
        
        
        #Each image has its own path inside of the save_path. It is
        #made up of a hash that is split up in three parts to prevent
        #hitting file system limits on the number of files allowed in
        #one directory. The images with the names and sizes specified
        #in <tt>sizes</tt> are written to this directory.
        def path
          return nil if self.hash_string.blank?
          File.join(*self.hash_string.scan(/(.)(.)(.*)/).flatten)
        end
        
        
        #Returns a filename for a given size and extension. The
        #extension will be added automatically if not given.
        #(It's going to be either 'jpg' or 'gif')
        def filename(size = nil, ext = nil)
          size ||= sizes.keys.first.to_s
          ext ||= extension
          "#{size}.#{ext}"
        end
        
        
        #Determine the extension for this image. All images
        #are saved as either JPEG or GIF, depending on if
        #the uploaded image is an animation or not.
        def extension
          content_type == 'image/gif' ? 'gif' : 'jpg'
        end
        
        
        #Contains the hash for the different names and sizes to be
        #written. This is by default a copy of <tt>image_sizes</tt>
        #on the model class, but it can be changed on a per-image basis.
        #(An image won't remember the sizes you give it)
        def sizes
          @sizes ||= self.class.image_sizes.dup
        end
        
        
        def sizes=(new_sizes)
          @sizes = new_sizes
        end
        
        
        #The path from which the browser can read the image. It is
        #by default a copy of <tt>image_read_path</tt> on the model
        #class.
        def read_path
          @read_path ||= self.class.image_read_path.dup
        end
        
        
        def read_path=(new_path)
          @read_path = new_path
        end
        
        
        #Adds the image's own <tt>path</tt> to the <tt>read_path</tt>
        def read_path_with_own_path
          File.join(read_path, path)
        end
        
        
        #Adds a filename to <tt>read_path_with_own_path</tt>
        def read_path_with_filename(size = nil, ext = nil)
          File.join(read_path_with_own_path, filename(size, ext))
        end
        
        
        #The path in which the image's directory structure
        #will be written. It is by default a copy of
        #<tt>image_save_path</tt> on the image class.
        def save_path
          @save_path ||= self.class.image_save_path.dup
        end
        
        
        def save_path=(new_path)
          @save_path = new_path
        end
        
        
        #Adds the image's own <tt>path</tt> to the <tt>save_path<tt>
        def save_path_with_own_path
          File.join(save_path, path)
        end
        
        
        #Adds a filename to <tt>save_path_with_own_path</tt>
        def save_path_with_filename(size = nil, ext = nil)
          File.join(save_path_with_own_path, filename(size, ext))
        end
        
        
        private
        
          #Generates a hash to be used when creating the image's directory
          #structure. This method is run <tt>before_validation</tt>, and
          #<tt>hash_string</tt> is validated to be unique.
          def generate_hash_string#:doc:
            return true unless self.hash_string.nil?
            begin
              self.hash_string = Digest::MD5.hexdigest(Time.now.to_f.to_s)
            end while self.class.find_by_hash_string(self.hash_string)
          end
  

          #Scales and writes the image with the different names and sizes. The
          #<tt>file</tt> attribute can be a <tt>StringIO</tt> or <tt>Tempfile</tt>,
          #the two different types that can come from a form post, or a
          #<tt>Magick::ImageList</tt> from RMagick. The file can be omitted if
          #the record is not new, but is required in order for the record to
          #be saved the first time.
          #
          #If for some reason the image can't be written, the record will not be saved
          #and a message will be added to the record's errors.
          #
          #Make sure your server process has the rights to create directories at least
          #in the <tt>save_path</tt> directory. It will try to create <tt>save_path</tt>
          #if it doesn't exist, but will fail if it doesn't have the necessary rights.
          def process_image#:doc:
            
            if !self.file || (self.file.respond_to?(:length) && self.file.length == 0)
              if new_record?
                raise 'No file.'
              else
                return true
              end
            end
            
            self.original_filename = self.file.original_filename if self.file.respond_to?(:original_filename)
            
            unless self.file.is_a?(Array)
              #Read image data from form
              begin
                original = ::Magick::ImageList.new.concat(
                  ::Magick::Image.from_blob(
                    self.file.read
                  ).map{|im|
                    im.strip!
                  }
                )
              rescue
                raise 'Could not read image. Are you sure this is an image file?'
              end
            else#Image is already a Magick::ImageList
              original = self.file.is_a?(::Magick::ImageList) ? self.file : ::Magick::ImageList.new.concat(self.file)
            end
            
            #Scale/crop images
            begin
              #Will be a hash of [size, image] pairs, eg ['small', <Magick::ImageList>]
              scaled_images = sizes.map{|name,size|
              
                if size.is_a? Array
                  if size.size > 1
                    method = size[1].to_sym
                    size = size[0]
                  else
                    method = :scale
                    size = size[0]
                  end
                end
                
                [
                  name,
                  original.collect{|im|
                    im.change_geometry(size){|cols,rows,img|
                      if method == :crop
                        img.crop_resized(cols, rows, ::Magick::NorthWestGravity)
                      else# method == :scale
                        img.resize(cols, rows)
                      end
                    }
                  }
                ]
              }
            rescue Exception
              raise 'Could not scale image.'
            end
            
            #Write scaled images to files
            #Should possibly combine with scaling to consume less memory
            begin
              FileUtils.mkdir_p(save_path_with_own_path)
              delete_files#Delete old files
              scaled_images.each{|pair|
                if pair.last.size > 1#Assume image is animated
                  self.content_type = 'image/gif'
                  pair.last.write(save_path_with_filename(pair.first))
                else
                  self.content_type = 'image/jpeg'
                  pair.last.first.write(save_path_with_filename(pair.first))
                end
              }
            rescue Exception
              raise 'Could not write image.'
            end
          rescue Exception => e
            self.errors.add('file', e.message)
            delete_files
            return false
          ensure
            #Throw RMagick stuff out of memory
            #TODO: Not sure this works the way I think it does
            self.file = nil
            scaled_images = nil
            GC.start
          end
          
          
          #Delete the image's files from its <tt>save_path_with_own_path</tt>.
          #This method is called <tt>after_destroy</tt>.
          def delete_files#:doc:
            sizes.keys.each do |size|
              File.delete(save_path_with_filename(size))
            end
          rescue
          ensure
            return true
          end
      
      
      end

    
    end
  end
end