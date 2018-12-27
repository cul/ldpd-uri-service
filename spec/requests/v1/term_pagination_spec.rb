require 'rails_helper'

RSpec.describe 'Term Pagination', type: :request do
  let(:vocab) { FactoryBot.create(:vocabulary, string_key: 'spells', label: 'Spells') }

  before do
    (1..10).each do
      FactoryBot.create(:temp_term, vocabulary: vocab, pref_label: Faker::HarryPotter.unique.spell, custom_fields: {}, alt_label: [])
    end
    Faker::HarryPotter.unique.clear
  end

  it 'uses default pagination parameters' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms"
    expect(response.body).to be_json_eql(%(
      { "page":1, "per_page":20, "total_records":10}
    )).excluding('terms')
  end

  it 'sets params to default when parameters are less than 1' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms?per_page=-1&page=-3"
    expect(response.body).to be_json_eql(%(
      { "page":1, "per_page":20, "total_records":10 }
    )).excluding('terms')
  end

  it 'sets per_page to default when greater than 1000' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms?per_page=1001"
    expect(response.body).to be_json_eql(%(
      { "page":1, "per_page":20, "total_records":10 }
    )).excluding('terms')
  end

  it 'paginates results correctly to second page' do
    get_with_auth "/api/v1/vocabularies/#{vocab.string_key}/terms?per_page=5&page=2"
    expect(response.body).to have_json_size(5).at_path('terms')
    expect(response.body).to be_json_eql(%(
      { "page":2, "per_page":5, "total_records":10 }
    )).excluding('terms')
  end
end
