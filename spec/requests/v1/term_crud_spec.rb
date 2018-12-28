require 'rails_helper'

RSpec.describe 'CRUD /api/v1/vocabularies/:string_key/terms', type: :request do
  let(:vocabulary) do
    FactoryBot.create(:vocabulary, custom_fields: {
      classification: { label: 'Classification', data_type: 'string' },
      harry_potter_reference: { label: 'Harry Potter Reference', data_type: 'boolean' }
    })
  end

  before { vocabulary }

  describe 'GET /api/v1/vocabularies/:string_key/terms/:uri' do
    include_examples 'authentication required', 'get', '/api/v1/vocabularies/mythical_creatures/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2F1161301%2F'

    before do
      FactoryBot.create(:external_term,
        vocabulary: vocabulary,
        custom_fields: { 'classification': 'Horse' }
      )
    end

    context 'when :uri valid' do
      before do
        get_with_auth '/api/v1/vocabularies/mythical_creatures/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2F1161301%2F'
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end

      it 'returns one term' do
        expect(response.body).to be_json_eql(%(
          {
            "uri": "http://id.worldcat.org/fast/1161301/",
            "pref_label": "Unicorns",
            "alt_label": [],
            "authority": "fast",
            "term_type": "external",
            "classification": "Horse",
            "harry_potter_reference": null
          }
        )).excluding('uuid')
      end
    end

    context 'when :uri invalid' do
      before do
        get_with_auth '/api/v1/vocabularies/mythical_creatures/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2Fnot_valid%2F'
      end

      it 'returns error in json' do
        expect(response.body).to be_json_eql(%({ "errors": [{ "title": "Not Found" }] }))
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end

    context 'when vocabulary doesn\'t exist' do
      before do
        get_with_auth '/api/v1/vocabularies/fantastic_beasts/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2Fnot_valid%2F'
      end

      it 'returns error in json' do
        expect(response.body).to be_json_eql(%({ "errors": [{ "title": "Vocabulary not found." }] }))
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'POST /api/v1/vocabularies/:string_key/terms' do
    include_examples 'authentication required', 'post', '/api/v1/vocabularies/mythical_creatures/terms'

    context 'when successfully creating a new external term' do
      before do
        post_with_auth '/api/v1/vocabularies/mythical_creatures/terms', params: {
          pref_label: 'Minotaur (Greek mythological character)',
          uri: 'http://id.worldcat.org/fast/1023481',
          authority: 'fast',
          term_type: 'external',
          classification: 'Human'
        }
      end

      it 'creates a term record' do
        expect(Term.count).to be 1
        expect(Term.first.uri).to eql 'http://id.worldcat.org/fast/1023481'
      end

      it 'returns newly created term in json' do
        expect(response.body).to be_json_eql(%(
         {
           "pref_label": "Minotaur (Greek mythological character)",
           "alt_label": [],
           "uri": "http://id.worldcat.org/fast/1023481",
           "authority": "fast",
           "term_type": "external",
           "classification": "Human",
           "harry_potter_reference": null
         }
        )).excluding('uuid')
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end
    end

    context 'when successfully creating a new local term' do
      before do
        post_with_auth '/api/v1/vocabularies/mythical_creatures/terms', params: {
          pref_label: 'Hippogriff',
          alt_label: ['Hippogryph'],
          term_type: 'local',
          classification: 'Eagle'
        }
      end

      it 'creates a term record' do
        expect(Term.count).to be 1
        expect(Term.first.uri).not_to be_blank
        expect(Term.first.alt_label.first).to eql 'Hippogryph'
      end

      it 'returns newly created term in json' do
        expect(response.body).to be_json_eql(%(
          {
            "pref_label": "Hippogriff",
            "alt_label": ["Hippogryph"],
            "term_type": "local",
            "authority": null,
            "classification": "Eagle",
            "harry_potter_reference": null
          }
        )).excluding('uri', 'uuid')
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end
    end

    context 'when successfully creating a new temporary term' do
      before do
        post_with_auth '/api/v1/vocabularies/mythical_creatures/terms', params: {
          pref_label: 'Hippogriff',
          term_type: 'temporary',
        }
      end

      it 'creates term record' do
        expect(Term.count).to be 1
        expect(Term.first.uri).to start_with('temp:')
        expect(Term.first.pref_label).to eql 'Hippogriff'
      end

      it 'return newly created term in json' do
        expect(response.body).to be_json_eql(%(
          {
            "pref_label": "Hippogriff",
            "alt_label": [],
            "authority": null,
            "term_type": "temporary",
            "harry_potter_reference": null,
            "classification": null
          }
        )).excluding('uri', 'uuid')
      end

      it 'returns 201' do
        expect(response.status).to be 201
      end
    end

    context 'when uri is missing for external term' do
      before do
        post_with_auth '/api/v1/vocabularies/mythical_creatures/terms', params: {
          pref_label: 'Minotaur (Greek mythological character)',
          authority: 'fast',
          term_type: 'external',
          harry_potter_reference: false
        }
      end

      it 'returns 400' do
        expect(response.status).to be 400
      end

      it 'returns error in json' do
        expect(response.body).to be_json_eql(%(
          { "errors": [
            { "title": "Uri can't be blank" },
            { "title": "Uri hash can't be blank" }
          ]
          }
        ))
      end
    end

    context 'when creating a external term that already exists' do
      before do
        FactoryBot.create(:external_term, vocabulary: vocabulary)
        post_with_auth '/api/v1/vocabularies/mythical_creatures/terms', params: {
          pref_label: 'Unicorn',
          uri: 'http://id.worldcat.org/fast/1161301/',
          authority: 'fast',
          term_type: 'external'
        }
      end

      it 'returns 409' do
        expect(response.status).to be 409
      end

      it 'returns error in json' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Uri hash unique check failed. This uri already exists in this vocabulary." }] }
        ))
      end
    end

    context 'when creating a temporary term that already exists' do
      before do
        FactoryBot.create(:temp_term, vocabulary: vocabulary)
        post_with_auth '/api/v1/vocabularies/mythical_creatures/terms', params: {
          pref_label: 'Yeti',
          term_type: 'temporary'
        }
      end

      it 'returns 409' do
        expect(response.status).to be 409
      end

      it 'returns error in json' do
        expect(response.body).to be_json_eql(%(
          { "errors": [{ "title": "Uri hash unique check failed. This uri already exists in this vocabulary." }] }
        ))
      end
    end
  end

  describe 'PATCH /api/v1/vocabularies/:string_key/terms/:uri' do
    include_context 'authentication required', 'patch', '/api/v1/vocabularies/mythical_creatures/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2F1161301%2F'

    context 'when updating alt_label' do
      let(:term) do
        FactoryBot.create(:external_term,
                          vocabulary: vocabulary,
                          custom_fields: { 'classification' => 'Horses' })
      end

      before do
        patch_with_auth "/api/v1/vocabularies/mythical_creatures/terms/#{CGI.escape(term.uri)}", params: {
          alt_label: ['Uni']
        }
      end

      it 'updates alt_labels for term' do
        term.reload
        expect(term.alt_label).to contain_exactly 'Uni'
      end

      it 'preserves custom fields' do
        term.reload
        expect(term.custom_fields).to match('classification' => 'Horses')
      end

      it 'returns updated term' do
        expect(response.body).to be_json_eql(%(
          {
            "uri": "http://id.worldcat.org/fast/1161301/",
            "pref_label": "Unicorns",
            "alt_label": ["Uni"],
            "authority": "fast",
            "term_type": "external",
            "harry_potter_reference": null,
            "classification": "Horses"
          }
        )).excluding('uuid')
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when updating term_type' do
      let(:term) { FactoryBot.create(:external_term, vocabulary: vocabulary) }

      before do
        patch_with_auth "/api/v1/vocabularies/mythical_creatures/terms/#{CGI.escape(term.uri)}", params: {
          term_type: 'local'
        }
      end

      it 'does not update record' do
        term.reload
        expect(term.uri).not_to eql 'local'
      end

      it 'returns 200' do
        expect(response.status).to be 200
      end
    end

    context 'when attempting to update a uri that is not associated with a known term' do
      before do
        patch_with_auth "/api/v1/vocabularies/mythical_creatures/terms/#{CGI.escape('https://example.com/not/known')}", params: {
          pref_label: 'New Label'
        }
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'DELETE /api/v1/vocabularies/:string_key/terms/:uri' do
    include_context 'authentication required', 'delete', '/api/v1/vocabularies/mythical_creatures/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2F1161301%2F'

    context 'when deleting term' do
      let(:uri) { 'https://example.com/unicorns' }
      let(:term) { FactoryBot.create(:external_term, uri: uri, vocabulary: vocabulary) }

      before do
        delete_with_auth "/api/v1/vocabularies/mythical_creatures/terms/#{CGI.escape(term.uri)}"
      end

      it 'returns 204' do
        expect(response.status).to be 204
      end

      it 'removes term from database' do
        expect(Term.find_by(uri: uri)).to be nil
      end
    end

    context 'when attempting to delete a uri that is not associated with a known term' do
      before do
        delete_with_auth '/api/v1/vocabularies/mythical_creatures/terms/http%3A%2F%2Fid.worldcat.org%2Ffast%2Fnot_known%2F'
      end

      it 'returns 404' do
        expect(response.status).to be 404
      end
    end
  end

  describe 'OPTIONS /api/v1/vocabularies/:string_key/terms'
end
