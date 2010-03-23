require 'image_size'
require 'RMagick'
require 'smart_image/ratio_calculator'

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
    @canvas = Magick::Image.new @width, @height do
      self.background_color = "transparent"
    end
    
    yield self
    @canvas.destroy! unless @canvas.destroyed?
  end
  
  # Composite the given image data onto the SmartImage
  #
  # Accepts the following options:
  #
  # * x: coordinate of the upper left corner of the image (default 0)
  # * y: ditto, it's the y coordinate
  # * width: an alternate width. scales and preserves original aspect ratio
  # * height: alternate height, also scales and preserves aspect ratio
  # * preserve_aspect_ratio: should the aspect ratio be preserved? (default: true)
  def composite(data, options = {})
    img = Magick::ImageList.new
    img.from_blob data
    
    opts = {
      :x => 0,
      :y => 0,
      :width  => img.columns,
      :height => img.rows,
      :preserve_aspect_ratio => true
    }.merge(options)
  
    if opts[:preserve_aspect_ratio]
      composited_size = SmartImage::RatioCalculator.new(
        :source_width  => img.columns,
        :source_height => img.rows,
        :dest_width  => Integer(opts[:width]), 
        :dest_height => Integer(opts[:height])
      ).size
    
      dest_width, dest_height = composited_size.width, composited_size.height
    else
      dest_width, dest_height = Integer(opts[:width]), Integer(opts[:height])
    end
  
    img.thumbnail! dest_width, dest_height
    @canvas.composite! img, opts[:x], opts[:y], Magick::OverCompositeOp
  ensure
    img.destroy!
  end
  
  # Composite a given image file onto the SmartImage.  Accepts the same options
  # as the composite method
  def composite_file(file, options = {})
    composite File.read(file), options
  end
  
  # Write the resulting image out to disk
  def write(path)
    @canvas.write path
  end
end