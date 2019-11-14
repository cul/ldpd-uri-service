require 'rails_helper'

RSpec.describe 'Filtering terms', type: :request do
  let(:vocab) { FactoryBot.create(:vocabulary, :with_custom_field) }

  shared_examples 'json contains external term' do
    it 'contains external term' do
      expect(response.body).to include_json(
        {
          'alt_labels' => ['Uni'], 'authority' => 'fast',
          'harry_potter_reference' => true,
          'pref_label' => 'Unicorns', 'term_type' => 'external',
          'uri' => 'http://id.worldcat.org/fast/1161301/',
        }.to_json
      ).at_path('terms').excluding(:uuid)
    end
  end

  shared_examples 'json contains local term' do
    it 'contains local term' do
      expect(response.body).to include_json(
        {
          'alt_labels' => [],
          'authority' => nil,
          'harry_potter_reference' => true,
          'pref_label' => 'Dragons',
          'term_type' => 'local',
        }.to_json
      ).at_path('terms').excluding(:uuid, :uri)
    end
  end

  shared_examples 'json contains temporary term' do
    it 'contains temp term' do
      expect(response.body).to include_json(
        {
          'alt_labels' => [],
          'authority' => nil,
          'harry_potter_reference' => false,
          'pref_label' => 'Yeti',
          'term_type' => 'temporary',
          'uri' => 'temp:559aae72a74e0c9b6ccfadfe09f4da14c76808acc44ccc02ed5b5fc88d38f316',
        }.to_json
      ).at_path('terms').excluding(:uuid)
    end
  end

  shared_examples 'json includes pagination' do |offset, limit, total_records|
    it 'returns pagination information' do
      expect(response.body).to be_json_eql(
        { offset: offset, limit: limit, total_records: total_records }.to_json
      ).excluding('terms')
      expect(response.body).to have_json_size(total_records).at_path('terms')
    end
  end

  before do
    FactoryBot.create(:external_term, alt_labels: ['Uni'], vocabulary: vocab)
    FactoryBot.create(:local_term, vocabulary: vocab)
    FactoryBot.create(:temp_term, vocabulary: vocab)
  end

  context 'when terms are part of a closed vocabulary' do
    before do
      vocab.update(locked: true)
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms'
    end

    it 'returns 200' do
      expect(response.status).to be 200
    end
  end

  context 'with no filters' do
    include_context 'json contains temporary term'
    include_context 'json contains local term'
    include_context 'json contains external term'
    include_context 'json includes pagination', 0, 20, 3

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms'
    end

    it 'returns 200' do
      expect(response.status).to be 200
    end
  end

  context 'by query' do
    include_context 'json contains local term'
    include_context 'json includes pagination', 0, 20, 1

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?q=dragon'
    end
  end

  context 'by exact authority string' do
    include_context 'json contains external term'
    include_context 'json includes pagination', 0, 20, 1

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?authority=fast'
    end
  end

  context 'by exact uri string' do
    include_context 'json contains external term'
    include_context 'json includes pagination', 0, 20, 1

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?uri=http%3A%2F%2Fid.worldcat.org%2Ffast%2F1161301%2F'
    end
  end

  context 'by exact pref_label' do
    include_context 'json contains temporary term'
    include_context 'json includes pagination', 0, 20, 1

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?pref_label=Yeti'
    end
  end

  context 'by exact alt_labels' do
    include_context 'json contains external term'
    include_context 'json includes pagination', 0, 20, 1

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?alt_labels=Uni'
    end
  end

  context `by exact term_type` do
    include_context 'json contains temporary term'
    include_context 'json includes pagination', 0, 20, 1

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?term_type=temporary'
    end
  end

  context 'by custom field' do
    include_context 'json contains external term'
    include_context 'json contains local term'
    include_context 'json includes pagination', 0, 20, 2

    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?harry_potter_reference=true'
    end
  end

  context 'by invalid custom field' do
    before do
      get_with_auth '/api/v1/vocabularies/mythical_creatures/terms?dangerous=true'
    end

    it 'returns no results' do
      expect(response.body).to be_json_eql(
        '{ "offset":0, "limit":20, "total_records":0, "terms":[] }'
      )
    end
  end
end
