require File.dirname(__FILE__) + '/spec_helper'

describe SmartImage do
  before :all do
    @sample_image = File.dirname(__FILE__) + '/fixtures/mongoose.jpg'
    @output_image = File.dirname(__FILE__) + '/tmp/output.png'
  end
  
  it "obtains image information" do
    info = SmartImage.file_info(@sample_image)
    
    info.type.should == :jpeg
    info.width.should  == 1327
    info.height.should == 1260
  end
  
  it "composites images" do
    SmartImage.new(800, 400) do |image|
      image.composite_file @sample_image, :y => 15
      image.write @output_image
    end
  end
  
  it "scales when compositing" do
    SmartImage.new(800, 400) do |image|
      image.composite_file @sample_image, :y => 15
      image.composite_file @sample_image, :x => 100, :y => 30, :width => 250, :height => 100
      image.write @output_image
    end
  end
end