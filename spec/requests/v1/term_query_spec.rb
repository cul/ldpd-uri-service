require 'rails_helper'

RSpec.describe 'Querying terms', type: :request do
  include_examples 'authentication required', 'get', '/api/v1/vocabularies/mythical_creatures/terms'

  let(:vocabulary) do
    FactoryBot.create(:vocabulary, custom_fields: {
      harry_potter_reference: { label: 'Harry Potter Reference', data_type: 'boolean' }
    })
  end

  it 'for 2 character queries only returns results with exact matches' do
    term = FactoryBot.create(:external_term, vocabulary: vocabulary, pref_label: 'Me', alt_labels: [])
    FactoryBot.create(:external_term, vocabulary: vocabulary, pref_label: 'Meadows', alt_labels: [], uri: 'http://id.worldcat.org/fast/1013121')

    expected_results = [URIService::JSON.term(term, request: false)].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=me'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end

  it 'for 1 character queries only returns results with exact matches' do
    term = FactoryBot.create(:local_term, vocabulary: vocabulary, pref_label: 'I', alt_labels: [])
    FactoryBot.create(:local_term, vocabulary: vocabulary, pref_label: 'III', alt_labels: [])

    expected_search_results = [URIService::JSON.term(term, request: false)].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=i'
    expect(response.body).to be_json_eql(expected_search_results).at_path('terms')
  end

  context 'when querying with partial and complete queries' do
    let(:term) { FactoryBot.create(:local_term, pref_label: 'What a great value') }
    let(:expected_results) do
      [URIService::JSON.term(term, request: false)].to_json
    end

    before { term }

    valid_queries = [
      'Wha', 'What', 'What ', 'What a', 'What a ', 'What a g',
      'What a gr', 'What a gre', 'What a grea', 'What a great', 'What a great ',
      'What a great v', 'What a great va', 'What a great val', 'What a great valu',
      'What a great value', 'great', 'value'
    ]

    valid_queries.each do |q|
      it "returns expected results for query '#{q}' " do
        get_with_auth "/api/v1/vocabularies/mythical_creatures/terms?q=#{q}"
        expect(response.body).to be_json_eql(expected_results).at_path('terms')
      end
    end

    invalid_queries = ['z', 'W', 'Wh']

    invalid_queries.each do |q|
      it "returns no results for query '#{q}' " do
        get_with_auth "/api/v1/vocabularies/mythical_creatures/terms?q=#{q}"
        expect(response.body).to be_json_eql('[]').at_path('terms')
      end
    end
  end

  it 'does not query by URI' do
    term = FactoryBot.create(:external_term, vocabulary: vocabulary)

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=http%3A%2F%2Fid.worldcat.org%2Ffast%2F1161301%2F'
    expect(response.body).to be_json_eql('[]').at_path('terms')
  end

  it 'sorts exact matches first' do
    term1 = FactoryBot.create(:local_term, pref_label: 'Cat', uri: 'http://id.loc.gov/fake/111', vocabulary: vocabulary)
    term2 = FactoryBot.create(:local_term, pref_label: 'Catastrophe', uri: 'http://id.loc.gov/fake/222', vocabulary: vocabulary)
    term3 = FactoryBot.create(:local_term, pref_label: 'Catastrophic', uri: 'http://id.loc.gov/fake/333', vocabulary: vocabulary)

    expected_results = [
      URIService::JSON.term(term1, request: false), URIService::JSON.term(term2, request: false), URIService::JSON.term(term3, request: false)
    ].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=Cat'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end

  it 'sorts full word matches first when present, even if there are other words in the term and it would otherwise sort later alphabetically' do
    term1 = FactoryBot.create(:local_term, pref_label: 'A Catastrophe', uri: 'http://id.loc.gov/fake/111', vocabulary: vocabulary)
    term2 = FactoryBot.create(:local_term, pref_label: 'Not Catastrophic', uri: 'http://id.loc.gov/fake/222', vocabulary: vocabulary)
    term3 = FactoryBot.create(:local_term, pref_label: 'The Cat', uri: 'http://id.loc.gov/fake/333', vocabulary: vocabulary)

    expected_results = [
      URIService::JSON.term(term3, request: false), URIService::JSON.term(term1, request: false), URIService::JSON.term(term2, request: false)
    ].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=Cat'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end

  it 'sorts equally relevant results alphabetically' do
    term1 = FactoryBot.create(:local_term, pref_label: 'Steve Jobs', uri: 'http://id.loc.gov/fake/111', vocabulary: vocabulary)
    term2 = FactoryBot.create(:local_term, pref_label: 'Steve Kobs', uri: 'http://id.loc.gov/fake/111', vocabulary: vocabulary)
    term3 = FactoryBot.create(:local_term, pref_label: 'Steve Lobs', uri: 'http://id.loc.gov/fake/333', vocabulary: vocabulary)

    expected_results = [
      URIService::JSON.term(term1, request: false), URIService::JSON.term(term2, request: false), URIService::JSON.term(term3, request: false)
    ].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=Steve'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end

  it 'returns results for mid-word partial word queries' do
    term1 = FactoryBot.create(:local_term, pref_label: 'Supermanners', uri: 'http://id.loc.gov/fake/111', vocabulary: vocabulary)
    term2 = FactoryBot.create(:local_term, pref_label: 'Batmanners', uri: 'http://id.loc.gov/fake/222', vocabulary: vocabulary)

    expected_results = [
      URIService::JSON.term(term2, request: false), URIService::JSON.term(term1, request: false)
    ].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=man'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end

  it 'doesn\'t return results that do not include the query' do
    term1 = FactoryBot.create(:local_term, pref_label: 'Batmanners', uri: 'http://id.loc.gov/fake/222', vocabulary: vocabulary)
    term2 = FactoryBot.create(:local_term, pref_label: 'Supermanners', uri: 'http://id.loc.gov/fake/111', vocabulary: vocabulary)

    expected_results = [URIService::JSON.term(term1, request: false)].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=bat'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end


  it 'performs a case insensitive search' do
    term = FactoryBot.create(:local_term, pref_label: 'Batmanners', uri: 'http://id.loc.gov/fake/222', vocabulary: vocabulary)

    expected_results = [URIService::JSON.term(term, request: false)].to_json

    get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=bAtMaNnErS'
    expect(response.body).to be_json_eql(expected_results).at_path('terms')
  end
end
