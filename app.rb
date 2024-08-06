require 'sinatra'
require 'json'
require_relative 'lib/key_manager.rb'

key_manager = KeyManager.new

before do
  content_type :json
  key_manager.clean_expired_keys
end

get '/' do
  status 
  { message: 'Welcome to the API Key Server!'}.to_json
end

post '/generate_key' do
  key = key_manager.generate_key
  status 200
  { key: key }.to_json
end

get '/get_key' do
  key = key_manager.get_available_key
  if key
    status 200
    { key: key }.to_json
  else
   status 404
   { error: 'No available keys' }.to_json
  end
end

post '/unblock_key' do
  key = params['key']
  if key_manager.invalid_key(key)
    status 400
    { error: 'Key is required' }.to_json 
  else 
    if key_manager.unblock_key(key)
      status 200
      { status: 'Key unblocked' }.to_json
    else
      status 404
      { error: 'Key not found' }.to_json
    end
  end
end

delete '/delete_key' do
  key = params['key']
  if key_manager.invalid_key(key)
    status 400
    { error: 'Key is required' }.to_json 
  else
    if key_manager.delete_key(key)
      status 200
      { status: 'Key deleted' }.to_json
    else
      status 404
      { error: 'Key not found' }.to_json
    end
  end
end

post '/keep_alive' do
  key = params['key']
  if key_manager.invalid_key(key)
    status 400
    { error: 'Key is required' }.to_json
  else
    if key_manager.keep_alive_key(key)
      status 200
      { status: 'Key kept alive' }.to_json
    else
      status 404
      { error: 'Key not found' }.to_json
    end
  end
end
