# spec/requests/lego_sets_spec.rb
require 'rails_helper'

RSpec.describe 'Lego Sets API', type: :request do
  # # initialize test data 
  # let!(:lego_sets) { create_list(:lego_set, 10) }
  # let(:lego_set_id) { lego_sets.first.id }

  # # Test suite for GET /todos
  # describe 'GET /lego_sets' do
  #   # make HTTP get request before each example
  #   before { get '/lego_sets' }

  #   it 'returns lego_sets' do
  #     # Note `json` is a custom helper to parse JSON responses
  #     expect(json).not_to be_empty
  #     expect(json.size).to eq(10)
  #   end

  #   it 'returns status code 200' do
  #     expect(response).to have_http_status(200)
  #   end
  # end

  # # Test suite for GET /lego_sets/:id
  # describe 'GET /lego_sets/:id' do
  #   before { get "/lego_sets/#{lego_set_id}" }

  #   context 'when the record exists' do
  #     it 'returns the lego_set' do
  #       expect(json).not_to be_empty
  #       expect(json['id']).to eq(lego_set_id)
  #     end

  #     it 'returns status code 200' do
  #       expect(response).to have_http_status(200)
  #     end
  #   end

  #   context 'when the record does not exist' do
  #     let(:lego_set_id) { 100 }

  #     it 'returns status code 404' do
  #       expect(response).to have_http_status(404)
  #     end

  #     it 'returns a not found message' do
  #       expect(response.body).to match(/Couldn't find LegoSet with 'id'=100/)
  #     end
  #   end
  # end
end
