require 'sinatra'
require 'json'
require 'redis'

configure :development do
  set :bind, '192.168.33.98'
end

redis = Redis.new

# Home page
post '/groupme/:room/callback' do
  data = JSON.parse request.body.read

  puts data

  unless data['user_id'] == ""
    redis.publish params[:room], "#{data['name']} said #{data['text']}"
  end

  'good job'
end
