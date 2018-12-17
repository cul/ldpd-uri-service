require 'rails_helper'

RSpec.describe 'Custom Fields Requests', type: :request do
  let(:vocabulary) { FactoryBot.create(:vocabulary) }

  describe 'POST /api/v1/vocabularies/:string_key/custom_fields' do
    context 'when adding a new custom field' do
      before do
        post "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields",
             params: { field_key: 'harry_potter_reference', label: 'Harry Potter Reference', data_type: 'boolean' }
      end

      it 'returns custom field' do
        expect(response.body).to be_json_eql(%(
          { "field_key": "harry_potter_reference", "data_type": "boolean", "label": "Harry Potter Reference" }
        ))
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end

      it 'expect custom field to be added to vocabulary record' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to match(
          'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' }
        )
      end
    end

    context 'when adding a custom field that already exists' do
      before do
        vocabulary.custom_fields = { 'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' } }
        vocabulary.save

        post "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields",
             params: { field_key: 'harry_potter_reference', label: 'Harry Potter Reference', data_type: 'string' }
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Field key already exists" }] }
        ))
      end

      it 'returns 409' do
        expect(response.status).to be 409
      end

      it 'does not alter custom field' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to match(
          'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' }
        )
      end
    end

    context 'when adding a custom field without a data type' do
      before do
        post "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields",
             params: { field_key: 'harry_potter_reference', label: 'Harry Potter Reference' }
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          {
            "errors": [
              { "title": "Custom fields each custom_field must have a label and data_type defined" },
              { "title": "Custom fields data_type must be one of string, number or boolean" }
            ]
          }
        ))
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end

      it 'does not add custom field' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to be_blank
      end
    end

    context 'when adding a custom field that uses a reserved field name' do
      before do
        post "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields",
             params: { field_key: 'term_type', label: 'Harry Potter Reference', data_type: 'boolean' }
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Custom fields field_key cannot be a reserved field name" }] }
        ))
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end

      it 'does not add custom field' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to be_blank
      end
    end

    context 'when adding custom field to vocabulary that doesn\'t exist' do
      before do
        post '/api/v1/vocabularies/invalid/custom_fields',
             params: { field_key: 'harry_potter_reference', label: 'Harry Potter Reference', data_type: 'boolean' }
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Vocabulary not found." }] }
        ))
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end

    context 'when adding a custom field without a field_key' do
      before do
        post "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields",
             params: { label: 'Harry Potter Reference', data_type: 'boolean' }
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Field key must be present." }] }
        ))
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end
    end
  end

  describe 'PATCH /api/v1/vocabularies/:string_key/custom_fields/:field_key' do
    context 'when updating custom field that exists' do
      before do
        vocabulary.custom_fields = { 'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' } }
        vocabulary.save

        patch "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields/harry_potter_reference",
              params: { label: 'Wizarding World Reference' }
      end

      it 'returns custom field' do
        expect(response.body).to be_json_eql(%(
          {
            "field_key": "harry_potter_reference",
            "label": "Wizarding World Reference",
            "data_type": "boolean"
          }
        ))
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end

      it 'updates custom field' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to match(
          'harry_potter_reference' => { data_type: 'boolean', label: 'Wizarding World Reference' }
        )
      end
    end

    context 'when updating a custom field with an empty label' do
      before do
        vocabulary.custom_fields = { 'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' } }
        vocabulary.save

        patch "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields/harry_potter_reference",
              params: { label: '' }
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Custom fields each custom_field must have a label and data_type defined" }] }
        ))
      end

      it 'does not change custom field' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to match('harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' })
      end
    end

    context 'when updating custom field that does not exist' do
      before do
        patch "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields/harry_potter_reference",
              params: { label: 'Wizarding World Reference' }
      end

      it 'returns error' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Not Found" }] }
        ))
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end

      it 'does not add custom fields' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to be_blank
      end
    end
  end

  describe 'DELETE /api/v1/vocabularies/:string_key/custom_fields/:field_key' do
    before do
      vocabulary.custom_fields = {
        'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' },
        'classification'         => { data_type: 'string', label: 'Classification' }
      }
      vocabulary.save
    end

    context 'when deleting custom field that exists' do
      before do
        delete "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields/harry_potter_reference"
      end

      it 'returns 204' do
        expect(response.status).to be 204
      end

      it 'deletes correct custom field' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to match(
          'classification' => { data_type: 'string', label: 'Classification' }
        )
      end
    end

    context 'when deleting custom field that doesn\'t exists' do
      before do
        delete "/api/v1/vocabularies/#{vocabulary.string_key}/custom_fields/fake_field"
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end

      it 'does not change custom fields' do
        vocabulary.reload
        expect(vocabulary.custom_fields).to match(
          'harry_potter_reference' => { data_type: 'boolean', label: 'Harry Potter Reference' },
          'classification'         => { data_type: 'string', label: 'Classification' }
        )
      end
    end
  end
end
