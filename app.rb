require 'json'
require 'sinatra'
require 'classifier.rb' 

CLASSIFIER = Detexify::Classifier.new(Detexify::Extractors::Strokes::Features.new)

get '/status' do
  JSON :loaded => CLASSIFIER.loaded?, :progress => CLASSIFIER.progress
end

get '/symbols' do
  symbols = CLASSIFIER.symbols.map { |s| s.to_hash }
  # update with counts
  JSON symbols.map { |symbol| symbol.update(:samples => Classifier.count_samples(symbol)) }
end

post '/train' do
  halt 403, "Illegal id" unless params[:id] && CLASSIFIER.symbol(params[:id])
  halt 403, 'I want some payload' unless params[:strokes]
  begin
    strokes = JSON params[:strokes]
  rescue
    halt 403, "Strokes scrambled"
  end
  if strokes && !strokes.empty? && !strokes.first.empty?
    begin
      CLASSIFIER.train params[:id], strokes
    rescue Detexify::Classifier::TooManySamples
      # FIXME can I handle http status codes in the request? Wanna go restful
      #halt 403, "Thanks - i've got enough of these..."
      halt 200, JSON(:error => "Thanks but I've got enough of these...")
    end
  else
    halt 403, "These strokes look suspicious"
  end
  # TODO sanity check in command list
  halt 200, JSON(:message => "Symbol was successfully trained.")
  # TODO return new list of symbols and counts
end

# classifies a set of strokes
# post param 'strokes' must be [['x':int x, 'y':int y, 't':int time], [...]]
post '/classify' do
  halt 401, 'I want some payload' unless params[:strokes]
  strokes = JSON params[:strokes]
  hits = CLASSIFIER.classify strokes, { :skip => params[:skip] && params[:skip].to_i, :limit => params[:limit] && params[:limit].to_i }
  JSON hits
end