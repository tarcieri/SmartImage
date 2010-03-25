class SmartImage
  # Exception thrown for unimplemented features
  class NotImplementedError < StandardError; end
  
  # This class defines the set of methods all canvases are expected to implement
  # It also documents the set of methods that should be available for a canvas
  class BaseCanvas
    # Create a new canvas object of the given width and height
    def initialize(width, height)
      raise NotImplementedError, "some silly person forgot to define a constructor"
    end
    
    # Destroy the canvas (if you need to)
    def destroy
      not_implemented :destroy
    end
    
    # Has the canvas been destroyed already?
    def destroyed?
      not_implemented :destroyed?
    end
    
    # Composite another image onto this canvas
    def composite(image_data, width, height, options = {})
      not_implemented :composite
    end
    
    # Encode the image to the given format
    def encode(format, options = {})
      not_implemented :encode
    end
    
    #######
    private
    #######
    
    def not_implemented(meth)
      raise NotImplementedError, "#{meth} not implemented by #{self.class.inspect}"
    end
  end
end