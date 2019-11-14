require 'rails_helper'

RSpec.describe 'Term Pagination', type: :request do
  let(:vocab) { FactoryBot.create(:vocabulary, string_key: 'spells', label: 'Spells') }

  before do
    (1..10).each do
      FactoryBot.create(:temp_term, vocabulary: vocab, pref_label: Faker::HarryPotter.unique.spell, custom_fields: {}, alt_labels: [])
    end
    Faker::HarryPotter.unique.clear
  end

  it 'uses default pagination parameters' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms"
    expect(response.body).to be_json_eql(%(
      { "offset":0, "limit":20, "total_records":10}
    )).excluding('terms')
  end

  it 'sets params to default when parameters are less than 1' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms?offset=-1&limit=-3"
    expect(response.body).to be_json_eql(%(
      { "offset":0, "limit":20, "total_records":10 }
    )).excluding('terms')
  end

  it 'sets limit to max_limit when greater than max_limit' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms?limit=501"
    expect(response.body).to be_json_eql(%(
      { "offset":0, "limit":500, "total_records":10 }
    )).excluding('terms')
  end

  it 'paginates results correctly to second page' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms?limit=5&offset=5"
    expect(response.body).to have_json_size(5).at_path('terms')
    expect(response.body).to be_json_eql(%(
      { "offset":5, "limit":5, "total_records":10 }
    )).excluding('terms')
  end
end
