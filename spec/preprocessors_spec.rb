require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'preprocessors'

describe Detexify::Preprocessors::Strokes::EquidistantPoints do
  
  def distance p1, p2
    MyMath::euclidean_distance(Vector.elements(p1.values_at('x','y')), Vector.elements(p2.values_at('x','y')))
  end
  
  before do
    @distance = 0.01
    @pre = Detexify::Preprocessors::Strokes::EquidistantPoints.new :distance => @distance
    @stroke = [{'x'=>1,'y'=>1}, {'x'=>-1,'y'=>-3}, {'x'=>-1,'y'=>-1}]
  end
  
  it "should make points in strokes equidistantly distributed" do
    stroke = @pre.process @stroke
    previous = nil
    stroke.each do |point|
      if previous
        # not using be_close because distance in cusps can be smaller
        distance(previous, point).should <= @distance + @distance/100
        previous = point
      else
        previous = point
      end
    end
  end
  
  it "should nearly preserve the start and the end" do
    stroke = @pre.process @stroke
    [:first, :last].each do |m|
      distance(stroke.send(m), @stroke.send(m)).should be_close(0, @distance)      
    end
  end
      
end

describe Detexify::Preprocessors::Strokes::ToImage do
  
  it "should create an image from the strokes"
  
end
