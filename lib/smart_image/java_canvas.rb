require 'java'
require 'smart_image/base_canvas'

class SmartImage
  # Canvas object backed by Java Graphics2D
  class JavaCanvas < BaseCanvas
    java_import java.awt.image.BufferedImage
    java_import javax.imageio.ImageIO
    java_import java.io.ByteArrayInputStream
    java_import java.io.ByteArrayOutputStream
    
    def initialize(width, height)
      @canvas = BufferedImage.new width, height, BufferedImage::TYPE_INT_ARGB
    end
    
    # Stub out destroy since Java actually garbage collects crap, unlike... C
    def destroy
    end
    
    # Composite the given image data onto the canvas
    def composite(image_data, options = {})
      info = SmartImage.info image_data
      opts = {
        :width  => info.width,
        :height => info.height,
        :x => 0,
        :y => 0
      }.merge(options)
      
      input_stream = ByteArrayInputStream.new image_data.to_java_bytes
      image = ImageIO.read input_stream
      raise FormatError, "invalid image" unless image
      
      graphics = @canvas.graphics
      graphics.draw_image image, opts[:x], opts[:y], opts[:width], opts[:height], nil
    end
    
    # Load the given file as an alpha mask for the image
    def alpha_mask(image_data, options = {})
      input_stream = ByteArrayInputStream.new image_data.to_java_bytes
      mask = ImageIO.read input_stream
      
      width = mask.width
      image_data, mask_data = Java::int[width].new, Java::int[width].new
      
      mask.height.times do |y|
        # fetch a line of data from each image
        @canvas.get_rgb 0, y, width, 1, image_data, 0, 1
        mask.get_rgb 0, y, width, 1, mask_data, 0, 1
        
        width.times do |x|
          # mask away the alpha
          color = image_data[x] & 0x00FFFFFF 
          
          # turn red from the mask into alpha
          alpha = (mask_data[x] & 0x00FF0000) << 8 
          
          image_data[x] = color | alpha
        end
        
        @canvas.set_rgb 0, y, width, 1, image_data, 0, 1
      end
    end
    
    # Encode the image to the given format
    def encode(format, options = {})
      output_stream = ByteArrayOutputStream.new
      ImageIO.write(@canvas, format.to_s, output_stream)
      String.from_java_bytes output_stream.to_byte_array
    end
  end
  
  # Java is our Canvas on Java, duh!
  Canvas = JavaCanvas
end
