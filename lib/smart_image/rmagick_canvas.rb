require 'RMagick'
require 'smart_image/base_canvas'

class SmartImage
  # Canvas object, backed by RMagick
  class RMagickCanvas
    def initialize(width, height)
      @canvas = Magick::Image.new width, height do
        self.background_color = "transparent"
      end
    end
    
    def destroy
      @canvas.destroy!
    end
    
    def destroyed?
      @canvas.destroyed?
    end
    
    def composite(image_data, options = {})
      image = Magick::ImageList.new
      image.from_blob image_data
      
      opts = {
        :width => image.columns,
        :height => image.rows,
        :x => 0,
        :y => 0
      }.merge(options)      
      
      image.thumbnail! opts[:width], opts[:height]
      @canvas.composite! image, opts[:x], opts[:y], Magick::OverCompositeOp
    ensure
      image.destroy!
    end
    
    # Encode this image into the given format (as a file extension)
    def encode(format, options = {})
      @canvas.format = format.to_s.upcase
      @canvas.to_blob
    end
  end
end