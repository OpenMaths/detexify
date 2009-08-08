require 'mongo'
require 'digest/sha1'

module Detexify
  
  class CappedContainer
    
    include Enumerable
    
    def initialize limit
      @limit = limit
      @hash = Hash.new { |h,v| h[v] = [] }
    end
    
    def clear
      @hash = Hash.new { |h,v| h[v] = [] }
    end
    
    def limit= newlimit
      if newlimit < @limit
        @hash.each do |_, a|
          while a.size > newlimit
            a.shift
          end
        end
      end
      @limit = newlimit
    end
    
    def << sample
      a = @hash[sample.symbol_id]
      a << sample
      a.shift if a.size > @limit
      self
    end
      
    def each &block
      @hash.each do |id, a|
        a.each do |sample|
          yield sample
        end
      end
    end
    
  end
  
  class Sample
    
    @@sample_limit = 100
    @@db = XGen::Mongo::Driver::Mongo.new(ENV['mongo'] || 'localhost').db("detexify")
    # there will also be capped collections for each id
    
    @@memcache = CappedContainer.new @@sample_limit
    
    @@progress = Class.new do
      def + num
        @num ||= 0
        @num += num
        self
      end
      
      def inc
        self + 1
      end
      
      def to_i
        [100*@num/Latex::Symbol::List.size, 100].min
      end
    end.new
    
    def self.progress
      @@progress.to_i
    end
    
    def self.db=thedb
      @@db = thedb
    end
    
    def self.sample_limit=limit
      @@sample_limit = limit
      @@memcache.limit = limit
    end

    def initialize h
      # :feature_vector, :strokes, :symbol_id
      @sample = h
    end
    
    [:feature_vector, :strokes, :symbol_id].each do |m|
      define_method m do
        @sample[m.to_s]
      end

      define_method :"#{m}=" do |val|
        @sample[m.to_s] = val
      end
    end
    
    def save
      @sample['_id'] = @@db.collection('samples').save(@sample)
      # create db cache as capped collection
      sid = @sample['symbol_id'].to_s
      hid = sid #Digest::SHA1.hexdigest(sid)
      unless @@db.collection_names.include? hid
        @@db.create_collection hid, :capped => true, :max => @@sample_limit
      end
      @@db.collection(hid).save(@sample.dup.delete_if { |k,_| k != 'feature_vector' })
      # and push into memcache
      @@memcache << self.class.new(@sample.dup).strip!
      # but return sample from collection('samples')
      @sample # this is the hash from the db - not self
    end
    
    def self.each_stripped &block
      @@memcache.each(&block)
    end
    
    def self.load(join = false)
      Thread.abort_on_exception = true
      @load_thread = Thread.new do
        Latex::Symbol::List.each do |symbol|
          sid = symbol.id.to_s
          hid = sid #Digest::SHA1.hexdigest(sid)
          if @@db.collection_names.include? hid # yeah! cached samples in db
            @@db.collection(hid).find().each do |h|
              @@memcache << self.new(h.update('symbol_id' => sid)).strip!
            end
          else # no db cache - create it
            @@db.create_collection hid, :capped => true, :max => @@sample_limit
            @@db.collection('samples').find('symbol_id' => sid).sort_by { rand }[0..(@@sample_limit-1)].each do |h|
              # save to db cache and push to memcache
              stripped = self.new(h).strip!
              @@db.collection(hid).save(h.delete_if { |k,_| k != 'feature_vector' })
              @@memcache << stripped
            end # FIXME symbols/strings
          end
          @@progress.inc
        end # Latex::Symbol::List.each
      end
      @load_thread.join if join
    end
    
    def self.unload
      @@memcache.clear
    end
    
    def symbol
      Latex::Symbol[symbol_id.to_sym]
    end

    def strip!
      @sample.delete_if { |k,_| !%w(symbol_id feature_vector).include? k }
      self.extend(Module.new do
        def save
          raise "Don't save a stripped sample!"
        end
      end)
    end
    
  end
  
end