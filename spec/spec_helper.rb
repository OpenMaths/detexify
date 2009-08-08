require 'mongo'
MONGO = XGen::Mongo::Driver::Mongo.new('localhost')

def setup_db
  MONGO.drop_database('detexify-test')
  MONGO.db('detexify-test')  
end

def teardown_db
  MONGO.drop_database('detexify-test')
end

# require 'spec/autorun'
$LOAD_PATH << File.join(File.dirname(__FILE__), '..')

require 'symbol'