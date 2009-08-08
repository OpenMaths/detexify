require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'couchrest'
require 'sample'

describe Detexify::Sample do
  before do
    @mongo = XGen::Mongo::Driver::Mongo.new('localhost')
    @mongo.drop_database('detexify-test')
    @db = @mongo.db('detexify-test')
    @limit = 2
    Detexify::Sample.db = @db
    Detexify::Sample.sample_limit = @limit
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>1,'y'=>1}]]
    @fvector = [1]
  end
  
  after do
    @mongo.drop_database('detexify-test')
  end
  
  it "can be saved" do
    sample = Detexify::Sample.new('strokes' => @strokes, 'feature_vector' => [1], 'symbol_id' => @symbol.id)
    lambda { sample.save }.should_not raise_error     
  end
  
  describe "a stripped sample" do
    
    before(:each) do
      @sample = Detexify::Sample.new('strokes' => @strokes, 'feature_vector' => [1], 'symbol_id' => @symbol.id).strip!
    end
    
    it "can not be saved" do
      lambda { @sample.save }.should raise_error
    end
    
  end
  
  describe "a saved sample" do
    
    before(:each) do
      @sample = Detexify::Sample.new('strokes' => @strokes, 'feature_vector' => [1], 'symbol_id' => @symbol.id)
      @hash = @sample.save
    end
    
    it "should be the first in the samples collection" do
      @hash.should == @db.collection('samples').find_first
    end
    
    it "should be saved in the db cache" do
      cached = @db.collection(@sample.symbol_id).find_first
      cached.should_not be_nil
      cached['feature_vector'].should == @sample.feature_vector
    end
    
  end
  
  describe "with some saved samples" do
    
    before(:each) do
      @samples = (1..3).map { |i| Detexify::Sample.new('strokes' => @strokes, 'feature_vector' => [i], 'symbol_id' => @symbol.id) }
      @hashes = @samples.map { |s| s.save }
    end
    
    it "should save all to the db" do
      @hashes.should == @db.collection('samples').find.to_a
    end

    it "should iterate over the last @limit added items" do
      a = []
      Detexify::Sample.each_stripped { |s| a << s }
      a.map { |s| [s.symbol_id, s.feature_vector] }.should == @samples[-@limit..-1].map { |s| [s.symbol_id, s.feature_vector] }
    end
        
    it "should not iterate over anything when unloaded" do
      Detexify::Sample.unload
      lambda { Detexify::Sample.each_stripped { raise 'Panic!' } }.should_not raise_error
    end
    
    describe "and loaded fresh" do
      before(:all) do
        Detexify::Sample.unload
        Detexify::Sample.load(true)
      end
      
      it "should iterate over @limit items" do
        num = 0
        Detexify::Sample.each_stripped { |s| num += 1 }
        num.should == @limit
      end
      
      it "should iterate over the last @limit added items" do
        a = []
        Detexify::Sample.each_stripped { |s| a << s }
        a.map { |s| [s.symbol_id, s.feature_vector] }.should == @samples[-@limit..-1].map { |s| [s.symbol_id, s.feature_vector] }
      end
      
      after(:all) do
        Detexify::Sample.unload
      end
    end
    
  end
  
end

describe Detexify::CappedContainer do
  
  before(:each) do
    @symbol = Latex::Symbol::List.first
    @strokes = [[{'x'=>1,'y'=>1}]]
    @sample = Detexify::Sample.new 'strokes' => @strokes, 'feature_vector' => [1], 'symbol_id' => @symbol.id
    @othersample = Detexify::Sample.new 'strokes' => @strokes, 'feature_vector' => [2], 'symbol_id' => @symbol.id
    @limit = 1
    @c = Detexify::CappedContainer.new @limit
  end
  
  it "can add a sample" # do
   #    (@c << @sample).for_id(@sample.symbol_id).should === [Detexify::MiniSample.new(@sample)]
   #  end
  
  it "should not add more that it's limit" # do
   #    (@c << @sample << @othersample).for_id(@sample.symbol_id).should have(@limit).samples
   #  end

  it "should contain the most recently added sample" # do
   #    (@c << @sample << @othersample).for_id(@sample.symbol_id).should include(@othersample)
   #  end

  it "should drop the oldest sample" # do
   #    (@c << @sample << @othersample).for_id(@sample.symbol_id).should_not include(@sample)
   #  end
  
end