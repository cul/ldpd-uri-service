require 'rails_helper'

RSpec.describe '/api/v1/vocabularies', type: :request do
  describe 'GET /api/v1/vocabularies' do
    include_examples 'authentication required', 'get', '/api/v1/vocabularies'

    before do
      FactoryBot.create(:vocabulary)
      FactoryBot.create(:vocabulary, string_key: 'names', label: 'Names')
    end

    it 'returns all vocabularies' do
      get_with_auth '/api/v1/vocabularies'
      expect(JSON.parse(response.body)).to match(
        'page' => 1,
        'per_page' => 20,
        'total_records' => 2,
        'vocabularies' => [
          { 'string_key' => 'mythical_creatures', 'label' => 'Mythical Creatures', 'custom_fields' => {} },
          { 'string_key' => 'names', 'label' => 'Names', 'custom_fields' => {} }
        ]
      )
    end

    it 'paginates results' do
      FactoryBot.create(:vocabulary, string_key: 'animals', label: 'Animals')
      get_with_auth '/api/v1/vocabularies?per_page=2&page=1'
      expect(response.body).to be_json_eql(%(
        {
          "page": 1, "per_page": 2, "total_records": 3,
          "vocabularies": [
            { "string_key": "animals", "label": "Animals", "custom_fields": {} },
            { "string_key": "mythical_creatures", "label": "Mythical Creatures", "custom_fields": {} }
          ]
        }
      ))
    end

    it 'sets per_page to max_per_page value when value exceeds max_per_page' do
      get_with_auth '/api/v1/vocabularies?page=1&per_page=501'
      expect(response.body).to be_json_eql(%(
        { "page": 1, "per_page": 500, "total_records": 2 }
      )).excluding('vocabularies')
    end
  end

  describe 'GET /api/v1/vocabularies/:string_key' do
    include_examples 'authentication required', 'get', '/api/v1/vocabularies/subjects'

    before { FactoryBot.create(:vocabulary) }

    it 'returns one vocabulary' do
      get_with_auth '/api/v1/vocabularies/mythical_creatures'
      expect(response.body).to be_json_eql(%(
        {
          "vocabulary": {
            "string_key": "mythical_creatures",
            "label": "Mythical Creatures",
            "custom_fields": {}
          }
        }
      ))
      expect(response.status).to be 200
    end

    it 'returns 404 if vocabulary not found' do
      get_with_auth '/api/v1/vocabularies/not_created_yet'
      expect(response.body).to be_json_eql(%({ "errors": [{ "title": "Not Found" }] }))
      expect(response.status).to be 404
    end
  end

  describe 'POST /api/v1/vocabularies' do
    include_examples 'authentication required', 'post', '/api/v1/vocabularies'

    context 'when successfully creating a new vocabulary' do
      before do
        post_with_auth '/api/v1/vocabularies', params: { vocabulary: { string_key: 'collections', label: 'Collections' } }
      end

      it 'creates a new vocabulary record' do
        expect(Vocabulary.count).to be 1
        expect(Vocabulary.first.string_key).to eql 'collections'
      end

      it 'returns newly created vocabulary in json' do
        expect(response.body).to be_json_eql(%(
          {
            "vocabulary": {
              "string_key": "collections",
              "label": "Collections",
              "custom_fields": {}
            }
          }
        ))
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end
    end

    context 'when string_key is missing' do
      before do
        post_with_auth '/api/v1/vocabularies', params: { vocabulary: { string_key: nil, label: 'Collections' } }
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end

      it 'returns error in json' do
        expect(response.body).to be_json_eql(%(
          {
            "errors": [
              { "title": "String key can't be blank" },
              { "title": "String key only allows lowercase alphanumeric characters and underscores and must start with a lowercase letter" }
            ]
          }
        ))
      end
    end

    context 'when creating a vocabulary that already exisits' do
      before do
        FactoryBot.create(:vocabulary)
        post_with_auth '/api/v1/vocabularies', params: { vocabulary: { string_key: 'mythical_creatures', label: 'Mythical Creatures' } }
      end

      it 'returns 409' do
        expect(response.status).to be 409
      end

      it 'returns error in json body' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "String key has already been taken" }] }
        ))
      end
    end
  end

  describe 'PATCH /api/v1/vocabularies/:string_key' do
    include_examples 'authentication required', 'patch', '/api/v1/vocabularies/subjects'

    before { FactoryBot.create(:vocabulary) }

    context 'when updating label' do
      before do
        patch_with_auth '/api/v1/vocabularies/mythical_creatures', params: { vocabulary: { label: 'FAST Mythical Creatures' } }
      end

      it 'updates label for vocabulary' do
        expect(Vocabulary.find_by(string_key: 'mythical_creatures').label).to eql 'FAST Mythical Creatures'
      end

      it 'returns new vocabulary' do
        expect(response.body).to be_json_eql(%(
          {
            "vocabulary": {
              "string_key": "mythical_creatures",
              "label": "FAST Mythical Creatures",
              "custom_fields": {}
            }
          }
        ))
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when updating string key' do
      before do
        patch_with_auth '/api/v1/vocabularies/mythical_creatures', params: { vocabulary: { string_key: 'fast_mythical_creatures' } }
      end

      it 'does not update record' do
        expect(response.body).to be_json_eql(%(
          {
            "vocabulary": {
              "string_key": "mythical_creatures",
              "label": "Mythical Creatures",
              "custom_fields": {}
            }
          }
        ))
      end

      # not sure if this is the correct reponse code.
      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when invalid string key' do
      before do
        patch_with_auth '/api/v1/vocabularies/names', params: { vocabulary: { label: 'FAST Names' } }
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'DELETE /api/v1/vocabularies/:string_key' do
    include_examples 'authentication required', 'delete', '/api/v1/vocabularies/subjects'

    context 'when deleting vocabulary' do
      let(:vocabulary) { FactoryBot.create(:vocabulary) }

      before do
        delete_with_auth "/api/v1/vocabularies/#{vocabulary.string_key}"
      end

      it 'returns 204' do
        expect(response.status).to be 204
      end

      it 'removes vocabulary from database' do
        expect(Vocabulary.find_by(string_key: vocabulary.string_key)).to be nil
      end
    end

    context 'when invalid string key' do
      before do
        delete_with_auth '/api/v1/vocabularies/names'
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'OPTIONS /vocabularies/:string_key' do
    it 'returns all fields for vocabularies'
    it 'returns custom fields for vocabularies'
  end
end
