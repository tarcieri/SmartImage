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
