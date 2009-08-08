require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'classifier'

describe Detexify::Classifier do

  before do
    @db = setup_db
    @limit = 2
    Detexify::Sample.db = @db
    Detexify::Sample.sample_limit = @limit
    @symbol = Latex::Symbol::List.first
    
    @strokes = [[{'x'=>0, 'y'=>0}, {'x'=>1, 'y'=>1}]]
    @samples = Detexify::Sample
    # put 10 samples in db
    @count = 10
    (@count -1).times do |i|
      @samples.new({
        'strokes' => @strokes, 'feature_vector' => [i], 'symbol_id' => @symbol.id
      }).save
    end
    @sample = @samples.new({
      'strokes' => @strokes, 'feature_vector' => [0], 'symbol_id' => @symbol.id
    })
    @sample.save
    @classifier = Detexify::Classifier.new lambda { |strokes| [0] }
  end
  
  after do
    teardown_db
  end
  
  it "should classify a new sample" do
    res = @classifier.classify(@strokes)
    res.should have(Latex::Symbol::List.size).elements

    # verify structure of response
    res.should be_an(Array)
    res.each do |hit|
      hit.should be_a(Hash)
      hit.should have_key(:symbol)
      hit.should have_key(:score)
    end      
  end
  
  it "should return results ordered by their score" do
    res = @classifier.classify(@strokes)
    # mapping to hit[:score] as sort_by is not stable
    res.map { |hit| hit[:score] }.should === res.sort_by { |hit| hit[:score] }.map { |hit| hit[:score] }
  end
  
  it "should limit the results if requested" do
    res = @classifier.classify(@strokes, :limit => 1)
    res.should have(1).elements    
  end

  it "should skip results if requested" do
    res = @classifier.classify(@strokes)
    skip = @classifier.classify(@strokes, :skip => 1)
    skip.should === res[1..-1]
  end
  
  it "should limit the results if also skipped" do
    res = @classifier.classify(@strokes, :limit => 1, :skip => 1)
    res.should have(1).elements
  end
  
  it "should skip results if also limited" do
    res = @classifier.classify(@strokes, :limit => 2)
    skip = @classifier.classify(@strokes, :skip => 1, :limit => 1)
    skip.should === res[1, 1]    
  end
  
  it "should train a legal symbol" do
    lambda { @classifier.train(@symbol.id, @strokes) }.should_not raise_error
  end
  
  it "should not train an illegal symbol and raise an appropriate error" do
    lambda { @classifier.train('fubar', @strokes) }.should raise_error(Detexify::Classifier::IllegalSymbolId)
    lambda { @classifier.train(@symbol.id, 'fubar') }.should raise_error(Detexify::Classifier::DataMessedUp)
  end
  
  # FIXME this is a temporary spec - a need cleanup instead of limits
  describe "with a symbol trained to the limit" do
    
    before do
      # Symbol is in database once. Add another SAMPLE_LIMIT - 1 times.
      @limit.times { @classifier.train(@symbol.id, @strokes) }
    end
    
    it "should train that symbol again but don't load it into memory"
    
  end
  
  it "have correct sample counts" do
    @classifier.count_samples(@symbol.id).should == @count
    @classifier.count_samples(@symbol).should == @count
  end
  
  it "should regenerate features"

end