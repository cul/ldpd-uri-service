require 'rails_helper'

describe '/api/v1/vocabularies', type: :request do
  describe 'GET /api/v1/vocabularies' do
    before do
      FactoryBot.create(:vocabulary)
      FactoryBot.create(:vocabulary, string_key: 'names', label: 'Names')
    end

    it 'returns all vocabularies' do
      get '/api/v1/vocabularies'
      expect(JSON.parse(response.body)).to match(
        'vocabularies' => [
          { 'string_key' => 'subjects', 'label' => 'Subjects' },
          { 'string_key' => 'names', 'label' => 'Names' }
        ]
      )
    end
  end

  describe 'GET /api/v1/vocabularies/:string_key' do
    before { FactoryBot.create(:vocabulary) }

    it 'returns one vocabulary' do
      get '/api/v1/vocabularies/subjects'
      expect(JSON.parse(response.body)).to match('string_key' => 'subjects', 'label' => 'Subjects')
      expect(response.status).to be 200
    end

    it 'returns 404 if vocabulary not found' do
      get '/api/v1/vocabularies/not_created_yet'
      expect(JSON.parse(response.body)).to match('error' => { 'message' => 'Not Found' })
      expect(response.status).to be 404
    end
  end

  describe 'POST /api/v1/vocabularies' do
    context 'when successfully creating a new vocabulary' do
      before do
        post '/api/v1/vocabularies', params: { string_key: 'collections', label: 'Collections' }
      end

      it 'creates a new vocabulary record' do
        expect(Vocabulary.count).to be 1
        expect(Vocabulary.first.string_key).to eql 'collections'
      end

      it 'returns newly created vocabulary in json' do
        expect(JSON.parse(response.body)).to match(
          'string_key' => 'collections',
          'label' => 'Collections'
        )
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end
    end

    context 'when string_key is missing' do
      before do
        post '/api/v1/vocabularies', params: { string_key: nil, label: 'Collections'}
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end

      it 'returns error in json' do
        expect(JSON.parse(response.body)).to match('error' => { 'messages' => 'validation errors here' })
      end
    end
  end

  describe 'PATCH /api/v1/vocabularies/:string_key' do
    before { FactoryBot.create(:vocabulary) }

    context 'when updating label' do
      before do
        patch '/api/v1/vocabularies/subjects', params: { label: 'FAST Subjects' }
      end

      it 'updates label for vocabulary' do
        expect(Vocabulary.find_by(string_key: 'subjects').label).to eql 'FAST Subjects'
      end

      it 'returns new vocabulary' do
        expect(JSON.parse(response.body)).to match('string_key' => 'subjects', 'label' => 'FAST Subjects')
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when updating string key' do
      before do
        patch '/api/v1/vocabularies/subjects', params: { string_key: 'fast_subjects' }
      end

      it 'does not update record' do
        expect(JSON.parse(response.body)).to match('string_key' => 'subjects', 'label' => 'Subjects')
      end

      # not sure if this is the correct reponse code.
      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when invalid string key' do
      before do
        patch '/api/v1/vocabularies/names', params: { label: 'FAST Names' }
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'DELETE /api/v1/vocabularies/:string_key' do
    context 'when deleting vocabulary' do
      before do
        FactoryBot.create(:vocabulary)
        delete '/api/v1/vocabularies/subjects'
      end

      it 'returns 204' do
        expect(response.status).to be 204
      end

      it 'removes vocabulary from database' do
        expect(Vocabulary.find_by(string_key: 'subjects')).to be nil
      end
    end

    context 'when invalid string key' do
      before do
        delete '/api/v1/vocabularies/names'
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
