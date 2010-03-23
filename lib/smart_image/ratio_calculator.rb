class SmartImage
  class RatioCalculator
    # Create a new RatioCalculator object with the given options
    def initialize(options = {})
      @options = options
    end
  
    # Calculate the resulting size given a particular set of contraints
    def size(options = {})
      opts = @options.merge(options)
    
      source = Size.new opts[:source_width], opts[:source_height]
      bounds = Size.new opts[:dest_width],   opts[:dest_height]
    
      # Calculate what the width would be if we matched the dest height
      naive_width = bounds.height * source.aspect_ratio
    
      # If it fits, use it!
      if naive_width <= bounds.width
        width  = naive_width
        height = naive_width / source.aspect_ratio
      # Otherwise, the height must fit
      else
        height = bounds.width / source.aspect_ratio
        width  = height * source.aspect_ratio
      end

      return Size.new(width, height)
    end
  
    #
    # Struct to hold the resulting size and compute aspect ratios
    #
    class Size < Struct.new(:width, :height, :aspect_ratio)
      def initialize(width, height)
        width, height = Integer(width), Integer(height)
        aspect_ratio = width.to_f / height      
        super(width, height, aspect_ratio)
      end
    end
  end
end