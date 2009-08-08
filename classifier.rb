require 'couchrest'
require 'matrix'
require 'math'
require 'preprocessors'
require 'extractors'
require 'symbol'
require 'sample'

module Detexify

  class Classifier

    K = 5

    def initialize extractor, options = {}
      @extractor = extractor
      if defined? L
        L.debug "loading samples..."
      end
      Sample.load # TODO maybe load lazy?
    end
    
    # returns load status in percent
    def progress
      Sample.progress
    end
    
    def loaded?
      Sample.progress == 100
    end

    def symbols
      @symbols ||= Latex::Symbol::List # FIXME do I need @symbols?  
    end

    def symbol id
      Latex::Symbol[id]
    end

    def count_samples symbol
      Sample.count symbol.to_sym
    end

    # errors for use with train and classify
    IllegalSymbolId = Class.new(ArgumentError)
    DataMessedUp = Class.new(ArgumentError)
    TooManySamples = Class.new(RuntimeError)

    # train the classifier
    def train id, strokes
      raise IllegalSymbolId unless Latex::Symbol[id]
      raise DataMessedUp unless data_ok?(strokes)
      # preprocess
      strokes.each do |stroke|
        stroke.each do |point|
          point['t'] = point['t'].to_f
        end
      end
      #raise TooManySamples if count_samples(id) >= SAMPLE_LIMIT
      # TODO offload feature extraction to a job queue
      f = extract_features strokes
      sample = Sample.new('symbol_id' => id, 'feature_vector' => f, 'strokes' => strokes)
      sample.save
    end

    def classify strokes, options = {} # TODO modules KNN, Mean, etc. for different classifier types? 
      raise DataMessedUp unless data_ok?(strokes)
      f = extract_features strokes
      # use nearest neighbour classification
      # sort by distance and find minimal distance for each command
      minimal_distance_hash = {}
      samples = Sample.enum_for(:each_stripped)
      sorted = samples.sort_by do |sample|
        # FIXME catch exception Dimension mismatch here
        d = distance(Vector.elements(f), Vector.elements(sample.feature_vector))
        minimal_distance_hash[sample.symbol_id] = d if (!minimal_distance_hash[sample.symbol_id]) || (minimal_distance_hash[sample.symbol_id] > d)
        d
      end
      neighbours = Hash.new { |h,v| h[v] = 0 } # holds nearest neighbours to pattern
      # K is number of best matches we want in the list
      while (!sorted.empty?) && (neighbours.size < K)
        sample = sorted.shift # next nearest sample to f
        neighbours[sample.symbol_id] += 1
      end
      max_nearest_neighbours_distance = neighbours.map { |id, _| minimal_distance_hash[id] }.max
      # TODO explain
      computed_neighbour_distance = {}
      neighbours.each { |id, num| computed_neighbour_distance[id] = max_nearest_neighbours_distance/num }
      minimal_distance_hash.update(computed_neighbour_distance)
      # we are adding everything that is not in the nearest list with LARGE distance
      missing = symbols.map { |symbol| symbol.id } - minimal_distance_hash.keys
      # FIXME this feels slow
      ret = minimal_distance_hash.map { |id, dist| { :symbol => Latex::Symbol[id].to_hash, :score => dist } }.sort_by{ |h| h[:score] } + missing.map { |id| { :symbol => Latex::Symbol[id].to_hash, :score => 999999} }
      # limit and skip
      ret = ret[options[:skip] || 0, options[:limit] || ret.size] if [:limit, :skip].any? { |k| options[k] }
      return ret
    end

    def distance x, y
      # TODO find a better distance function
      MyMath.euclidean_distance(x, y)
    end

    def regenerate_features
      puts "regenerating features"
      # TODO do this by symbol
      @samples.all.each do |s|
        f = extract_features(s.source, s.strokes)
        puts f.inspect
        s.feature_vector = f
        s.save
      end
      puts "done."
    end

    def extract_features strokes
      @extractor.call(strokes)
    end
    
    private
    
    def data_ok? strokes
      # TODO more and better checks
      strokes.is_a?(Array)
    end

  end

end