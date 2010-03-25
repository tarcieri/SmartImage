require 'image_size'
require 'smart_image/ratio_calculator'

# Load the appropriate canvas object for the current environment
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
    
    # Return a handle to the canvas class for this environment
    def canvas_class
      if defined? JRUBY_VERSION
        JavaCanvas
      else
        RMagickCanvas
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
    @canvas = self.class.canvas_class.new @width, @height
    
    yield self
    @canvas.destroy unless @canvas.destroyed?
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
  
    if opts[:preserve_aspect_ratio]
      composited_size = SmartImage::RatioCalculator.new(
        :source_width  => info.width,
        :source_height => info.height,
        :dest_width  => Integer(opts[:width]), 
        :dest_height => Integer(opts[:height])
      ).size
    
      dest_width, dest_height = composited_size.width, composited_size.height
    else
      dest_width, dest_height = Integer(opts[:width]), Integer(opts[:height])
    end
  
    @canvas.composite data, :width  => dest_width,
                            :height => dest_height,
                            :x      => opts[:x], 
                            :y      => opts[:y]
  end
  
  # Composite a given image file onto the SmartImage.  Accepts the same options
  # as the composite method
  def composite_file(file, options = {})
    composite File.read(file), options
  end
  
  # Encode the image with the given format (a file extension) and return it 
  # as a string.  Doesn't accept any options at present.  The options hash is
  # just there to annoy you and make you wish it had more options.
  def encode(format, options = {})
    # Sorry .jpeg lovers, I'm one of you too but the standard is jpg
    format = :jpg if format.to_s == 'jpeg'
    
    @canvas.encode format, options
  end
  
  # Write the resulting image out to disk.  Picks format based on filename.
  # Takes the same options as encode
  def write(path, options = {})    
    format = File.extname(path).sub(/^\./, '')
    File.open(path, 'w') { |file| file << encode(format, options) }
  end
end