require 'rails_helper'

RSpec.describe '/api/v1/vocabularies', type: :request do
  describe 'GET /api/v1/vocabularies' do
    before do
      FactoryBot.create(:vocabulary)
      FactoryBot.create(:vocabulary, string_key: 'names', label: 'Names')
    end

    it 'requires authentication' do
      get '/api/v1/vocabularies'
      expect(JSON.parse(response.body)).to match('errors' => [ { 'title' => 'Unauthorized' } ])
      expect(response.status).to be 401
    end

    it 'returns all vocabularies' do
      get_with_auth '/api/v1/vocabularies'
      expect(JSON.parse(response.body)).to match(
        'vocabularies' => [
          { 'string_key' => 'mythical_creatures', 'label' => 'Mythical Creatures', 'custom_fields' => {} },
          { 'string_key' => 'names', 'label' => 'Names', 'custom_fields' => {} }
        ]
      )
    end
  end

  describe 'GET /api/v1/vocabularies/:string_key' do
    before { FactoryBot.create(:vocabulary) }

    it 'requires authentication' do
      get '/api/v1/vocabularies/subjects'
      expect(JSON.parse(response.body)).to match('errors' => [ { 'title' => 'Unauthorized' } ])
      expect(response.status).to be 401
    end

    it 'returns one vocabulary' do
      get_with_auth '/api/v1/vocabularies/mythical_creatures'
      expect(JSON.parse(response.body)).to match('string_key' => 'mythical_creatures', 'label' => 'Mythical Creatures', 'custom_fields' => {})
      expect(response.status).to be 200
    end

    it 'returns 404 if vocabulary not found' do
      get_with_auth '/api/v1/vocabularies/not_created_yet'
      expect(JSON.parse(response.body)).to match('errors' => [{ 'title' => 'Not Found' }])
      expect(response.status).to be 404
    end
  end

  describe 'POST /api/v1/vocabularies' do
    context 'when authentication is missing' do
      before do
        post '/api/v1/vocabularies', params: { string_key: 'collections', label: 'Collections' }
      end

      it 'returns an error message' do
        expect(JSON.parse(response.body)).to match('errors' => [ { 'title' => 'Unauthorized' } ])
      end

      it 'returns 401' do
        expect(response.status).to be 401
      end
    end

    context 'when successfully creating a new vocabulary' do
      before do
        post_with_auth '/api/v1/vocabularies', params: { string_key: 'collections', label: 'Collections' }
      end

      it 'creates a new vocabulary record' do
        expect(Vocabulary.count).to be 1
        expect(Vocabulary.first.string_key).to eql 'collections'
      end

      it 'returns newly created vocabulary in json' do
        expect(JSON.parse(response.body)).to match(
          'string_key' => 'collections',
          'label' => 'Collections',
          'custom_fields' => {}
        )
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end
    end

    context 'when string_key is missing' do
      before do
        post_with_auth '/api/v1/vocabularies', params: { string_key: nil, label: 'Collections' }
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
  end

  describe 'PATCH /api/v1/vocabularies/:string_key' do
    before { FactoryBot.create(:vocabulary) }

    context 'when missing authentication' do
      before do
        patch '/api/v1/vocabularies/subjects', params: { label: 'FAST Subjects' }
      end

      it 'returns an error' do
        expect(JSON.parse(response.body)).to match('errors' => [ { 'title' => 'Unauthorized' } ])
      end

      it 'returns 401' do
        expect(response.status).to be 401
      end
    end

    context 'when updating label' do
      before do
        patch_with_auth '/api/v1/vocabularies/mythical_creatures', params: { label: 'FAST Mythical Creatures' }
      end

      it 'updates label for vocabulary' do
        expect(Vocabulary.find_by(string_key: 'mythical_creatures').label).to eql 'FAST Mythical Creatures'
      end

      it 'returns new vocabulary' do
        expect(JSON.parse(response.body)).to match('string_key' => 'mythical_creatures', 'label' => 'FAST Mythical Creatures', 'custom_fields' => {})
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when updating string key' do
      before do
        patch_with_auth '/api/v1/vocabularies/mythical_creatures', params: { string_key: 'fast_mythical_creatures' }
      end

      it 'does not update record' do
        expect(JSON.parse(response.body)).to match('string_key' => 'mythical_creatures', 'label' => 'Mythical Creatures', 'custom_fields' => {})
      end

      # not sure if this is the correct reponse code.
      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when invalid string key' do
      before do
        patch_with_auth '/api/v1/vocabularies/names', params: { label: 'FAST Names' }
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'DELETE /api/v1/vocabularies/:string_key' do
    context 'when missing authentication' do
      before do
        FactoryBot.create(:vocabulary)
        delete '/api/v1/vocabularies/subjects'
      end

      it 'return an error' do
        expect(JSON.parse(response.body)).to match('errors' => [ { 'title' => 'Unauthorized' } ])
      end

      it 'returns 401' do
        expect(response.status).to be 401
      end
    end

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
