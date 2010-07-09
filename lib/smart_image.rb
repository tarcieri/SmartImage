require 'image_size'
require 'smart_image/ratio_calculator'

# Load the appropriate canvas class for the current environment
if defined? JRUBY_VERSION
  require 'smart_image/java_canvas'
else
  require 'smart_image/rmagick_canvas'
end

# SmartImage: it's like a Swiss Army Knife for images, but one of those tiny
# ones you can keep on your keychain.
class SmartImage
  # I'm sorry, I couldn't understand the data you gave me
  class FormatError < ArgumentError; end
  
  # Struct type containing information about a given image
  class Info < Struct.new(:width, :height, :type); end
  
  class << self
    # Obtain basic information about the given image data
    # Returns a SmartImage::Info object
    def info(data)
      img = ImageSize.new data
      raise FormatError, "invalid image" if img.get_type == "OTHER"
    
      Info.new(img.width, img.height, img.get_type.downcase.to_sym)
    end
    
    # Obtain information about a file
    # Returns a SmartImage::Info object
    def file_info(path)
      info File.read(path)
    end
    
    # Generate a thumbnail from the given image data
    # Options:
    # * width: max width of the image, or explicit width if not preserving
    #   aspect ratio
    # * height: ditto, except for height of course
    # * preserve_aspect_ratio: if true, ensure image fits within the given
    #   width/height restraints.
    # * format: file extension you'd ordinarily apply to an output file of
    #   the type you desire.  Supported formats are :jpg, :png, and :gif
    #   (default :png)
    def thumbnail(data, options = {})
      source_info = info data
      
      opts = {
        :width  => source_info.width,
        :height => source_info.height,
        :preserve_aspect_ratio => true,
        :format => :png
      }.merge(options)
      
      width, height = calculate_aspect_ratio source_info, opts
      
      # Set res so we can assign it within the SmartImage.new block
      res = nil
      
      SmartImage.new(width, height) do |image|
        image.composite data, :width  => width,
                              :height => height,
                              :preserve_aspect_ratio => false
                              
        res = image.encode opts[:format]
      end
      
      res
    end
    
    # Generate a thumbnail file from a given input file
    # Accepts the same options as SmartImage.thumbnail
    def thumbnail_file(input_path, output_path, options = {})
      opts = {
        :format => File.extname(output_path).sub(/^\./, '')
      }.merge(options)
      
      data = SmartImage.thumbnail File.read(input_path), opts
      File.open(output_path, 'w') { |file| file << data }
    end
    
    # Solve aspect ratio constraints based on source image info and
    # a given options hash.  This is mostly an internal method but
    # if you find it useful knock yourself out.
    def calculate_aspect_ratio(info, options)
      if options[:preserve_aspect_ratio]
        composited_size = SmartImage::RatioCalculator.new(
          :source_width  => info.width,
          :source_height => info.height,
          :dest_width  => Integer(options[:width]), 
          :dest_height => Integer(options[:height])
        ).size

        return composited_size.width, composited_size.height
      else
        return options[:width], options[:height]
      end
    end
  end
  
  # Create a new SmartImage of the given width and height.  Always takes a
  # block... no exceptions!  Returns a destroyed SmartImage object.
  #
  #  SmartImage.new(400, 300) do |compositor|
  #    compositor.image "foo/bar.jpg", :x => 10, :y => 10
  #    compositor.text  "Hello, world!", :x => 20, :y => 20
  #    compositor.write "baz/qux.jpg"
  #  end
  #
  # When used with a block, all images are automatically freed from memory
  def initialize(width, height, &block)
    raise ArgumentError, "give me a block, pretty please" unless block_given?
    
    @width, @height = Integer(width), Integer(height)
    @canvas = SmartImage::Canvas.new @width, @height
    
    yield self
    @canvas.destroy
    @canvas = DeadCanvas.new
  end
  
  # After the SmartImage#initialize block completes, the canvas is destroyed
  # and replaced with a DeadCanvas that doesn't let you do anything
  class DeadCanvas
    def method_missing(*args)
      raise ArgumentError, "your image exists only within the SmartImage.new block"
    end
  end
  
  # Composite the given image data onto the SmartImage
  #
  # Accepts the following options:
  #
  # * x: coordinate of the upper left corner of the image (default 0)
  # * y: ditto, it's the y coordinate
  # * width: an alternate width
  # * height: alternate height
  # * preserve_aspect_ratio: should the aspect ratio be preserved? (default: true)
  def composite(data, options = {})
    info = self.class.info data
    
    opts = {
      :x => 0,
      :y => 0,
      :width  => info.width,
      :height => info.height,
      :preserve_aspect_ratio => true
    }.merge(options)
  
    dest_width, dest_height = self.class.calculate_aspect_ratio info, opts
  
    @canvas.composite data, :width  => Integer(dest_width),
                            :height => Integer(dest_height),
                            :x      => opts[:x], 
                            :y      => opts[:y]
  end
  
  # Composite a given image file onto the SmartImage.  Accepts the same options
  # as the composite method
  def composite_file(file, options = {})
    composite File.read(file), options
  end
  
  # Apply an alpha mask from the given image data.  Doesn't accept any options
  # right now, sorry.  It's just another useless dangling options hash.
  def alpha_mask(data, options = {})
    @canvas.alpha_mask data
  end
  
  # Apply an alpha mask from the given file.  Accepts the same options as the
  # alpha_mask method.
  def alpha_mask_file(file, options = {})
    alpha_mask File.read(file), options
  end
  
  # Encode the image with the given format (a file extension) and return it 
  # as a string.  Doesn't accept any options at present.  The options hash is
  # just there to annoy you and make you wish it had more options.
  def encode(format, options = {})
    # Sorry .jpeg lovers, I'm one of you too but the standard is jpg
    format = 'jpg' if format.to_s == 'jpeg'
    format = format.to_s
    
    raise ArgumentError, "invalid format: #{format}" unless %w(jpg png gif).include?(format)
    
    @canvas.encode format, options
  end
  
  # Write the resulting image out to disk.  Picks format based on filename.
  # Takes the same options as encode
  def write(path, options = {})    
    format = File.extname(path).sub(/^\./, '')
    File.open(path, 'w') { |file| file << encode(format, options) }
  end
end