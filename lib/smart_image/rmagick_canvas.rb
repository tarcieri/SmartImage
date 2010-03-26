require 'RMagick'
require 'smart_image/base_canvas'

class SmartImage
  # Canvas object, backed by RMagick
  class RMagickCanvas < BaseCanvas
    include Magick
    
    def initialize(width, height)
      @canvas = Image.new width, height do
        self.background_color = "transparent"
      end
    end
    
    def destroy
      @canvas.destroy!
    end
    
    def composite(image_data, options = {})
      image = ImageList.new
      image.from_blob image_data
      
      opts = {
        :width => image.columns,
        :height => image.rows,
        :x => 0,
        :y => 0
      }.merge(options)      
      
      image.thumbnail! opts[:width], opts[:height]
      @canvas.composite! image, opts[:x], opts[:y], OverCompositeOp
    ensure
      image.destroy!
    end
    
    # Load the given file as an alpha mask for the image
    def alpha_mask(image_data, options = {})
      mask = ImageList.new
      mask.from_blob image_data
      
      # Disable this image's alpha channel to use the opacity data as a mask
      mask.matte = false
      puts "OMG CopyOpacityCompositeOp!!!"
      @canvas.composite! mask, NorthWestGravity, CopyOpacityCompositeOp
    ensure
      mask.destroy!
    end
    
    # Encode this image into the given format (as a file extension)
    def encode(format, options = {})
      @canvas.format = format.to_s.upcase
      @canvas.to_blob
    end
  end
  
  # RMagick is our Canvas on everything besides JRuby.  Hope it works for you!
  Canvas = RMagickCanvas
end