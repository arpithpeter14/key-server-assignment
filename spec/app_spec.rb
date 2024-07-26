ENV['APP_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require_relative '../app.rb'

describe 'API Endpoints' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GET /' do
    it 'displays welcome message' do
      get '/'
      expect(last_response).to be_ok
      response = JSON.parse(last_response.body)
      expect(response['message']).to eq('Welcome to the API Key Server!')
    end
  end

  describe 'POST /generate_key' do
    it 'generates a new key' do
      post '/generate_key'
      expect(last_response).to be_ok
      response = JSON.parse(last_response.body)
      expect(response['key']).not_to be_nil
      # deleting this key so that it doesn't affect get_key example 2
      delete '/delete_key', key: response['key']
    end
  end

  describe 'GET /get_key' do
    it 'returns an available key' do
      post '/generate_key'
      get '/get_key'
      expect(last_response).to be_ok
      response = JSON.parse(last_response.body)
      expect(response['key']).not_to be_nil
    end

    it 'returns 404 if no keys are available' do
      get '/get_key'
      expect(last_response.status).to eq(404)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('No available keys')
    end
  end

  describe 'POST /unblock_key' do
    it 'unblocks a key' do
      post '/generate_key'
      get '/get_key'
      response = JSON.parse(last_response.body)
      key = response['key']

      post '/unblock_key', key: key
      expect(last_response).to be_ok
      response = JSON.parse(last_response.body)
      expect(response['status']).to eq('Key unblocked')
    end

    it 'returns 400 if key is not provided' do
      post '/unblock_key'
      expect(last_response.status).to eq(400)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('Key is required')
    end

    it 'returns 404 if key does not exist' do
      post '/unblock_key', key: 'not_key'
      expect(last_response.status).to eq(404)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('Key not found')
    end
  end

  describe 'DELETE /delete_key' do
    it 'deletes a key' do
      post '/generate_key'
      response = JSON.parse(last_response.body)
      key = response['key']

      delete '/delete_key', key: key
      expect(last_response).to be_ok
      response = JSON.parse(last_response.body)
      expect(response['status']).to eq('Key deleted')
    end

    it 'returns 400 if key is not provided' do
      delete '/delete_key'
      expect(last_response.status).to eq(400)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('Key is required')
    end

    it 'returns 404 if key does not exist' do
      delete '/delete_key', key: 'not_key'
      expect(last_response.status).to eq(404)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('Key not found')
    end
  end

  describe 'POST /keep_alive' do
    it 'keeps a key alive' do
      post '/generate_key'
      response = JSON.parse(last_response.body)
      key = response['key']

      post '/keep_alive', key: key
      expect(last_response).to be_ok
      response = JSON.parse(last_response.body)
      expect(response['status']).to eq('Key kept alive')
    end

    it 'returns 400 if key is not provided' do
      post '/keep_alive'
      expect(last_response.status).to eq(400)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('Key is required')
    end

    it 'returns 404 if key does not exist' do
      post '/keep_alive', key: 'non_existent_key'
      expect(last_response.status).to eq(404)
      response = JSON.parse(last_response.body)
      expect(response['error']).to eq('Key not found')
    end
  end
end
