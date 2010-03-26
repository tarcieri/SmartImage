SPEC_DIR = File.dirname(__FILE__)
require SPEC_DIR + '/spec_helper'

describe SmartImage do
  before :all do
    @mongoose   = SPEC_DIR + '/fixtures/mongoose.jpg'
    @mask       = SPEC_DIR + '/fixtures/mask.png'
    @output_dir = SPEC_DIR + '/tmp/'
  end
  
  it "obtains image information" do
    info = SmartImage.file_info(@mongoose)
    
    info.type.should == :jpeg
    info.width.should  == 1327
    info.height.should == 1260
  end
  
  it "composites images" do
    SmartImage.new(800, 400) do |image|
      image.composite_file @mongoose, :y => 15
      image.write @output_dir + 'composited.png'
    end
  end
  
  it "scales when compositing" do
    SmartImage.new(800, 400) do |image|
      image.composite_file @mongoose, :y => 15
      image.composite_file @mongoose, :x => 100, :y => 30, :width => 250, :height => 100
      image.write @output_dir + 'scaled.png'
    end
  end
  
  it "alpha masks images" do
    SmartImage.new(115, 95) do |image|
      image.composite_file @mongoose, :width => 115, 
                                      :height => 95,
                                      :preserve_aspect_ratio => false
                                      
      image.alpha_mask_file @mask
      image.write @output_dir + 'alpha_mask.png'
    end
  end
end