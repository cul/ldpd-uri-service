require 'rails_helper'

RSpec.describe Term, type: :model do
  let(:term_solr_doc) { URIService.solr.find_term(term.vocabulary.string_key, term.uri) }

  describe 'when creating a external term' do
    let(:term) { FactoryBot.create(:external_term) }

    it 'sets uri_hash' do
      expect(term.uri_hash).to eql '37e37aa82a659464081b368efa3f06dc12e56bd07ed8237f4c4a05f401015e52'
    end

    it 'sets uuid' do
      expect(term.uuid).not_to be blank?
    end

    context 'with an invalid URI' do
      let(:term) { FactoryBot.build(:external_term, uri: 'ldfkja') }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Uri is invalid'
      end
    end

    context 'with a missing uri' do
      let(:term) { FactoryBot.build(:external_term, uri: '') }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Uri can\'t be blank'
      end
    end

    context 'when uri is already represented in vocabulary' do
      let(:term_0) { FactoryBot.create(:external_term) }
      let(:term)   { FactoryBot.build(:external_term, vocabulary: term_0.vocabulary) }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Uri has already been added to this vocabulary'
      end
    end

    context 'when uri is already represented in a different vocabulary' do
      let(:term_0) { FactoryBot.create(:external_term) }
      let(:new_vocabulary) { FactoryBot.create(:vocabulary, string_key: 'fantastic_beasts') }
      let(:term) { FactoryBot.build(:external_term, custom_fields: {}, vocabulary: new_vocabulary) }

      it 'saves successfully' do
        expect(term.save).to be true
      end
    end

    it 'creates solr document' do
      expect(term_solr_doc).to include(
        'uri' => 'http://id.worldcat.org/fast/1161301/',
        'pref_label' => 'Unicorns',
        'term_type' => 'external',
        'authority' => 'fast',
        'custom_fields' => '{"harry_potter_reference":true}',
      )
    end
  end

  describe 'when creating a local term' do
    let(:term) { FactoryBot.create(:local_term) }

    it 'sets local term uri' do
      expect(term.uri).to start_with "#{URIService.local_uri_host}term"
    end

    it 'sets uri_hash' do
      expect(term.uri_hash).not_to be blank?
    end

    it 'sets uuid' do
      expect(term.uuid).not_to be blank?
    end

    context 'when missing local_uri_host in config/uri_service.yml' do
      before do
        stub_const('URI_SERVICE_CONFIG', {})
      end

      it 'raises error' do
        expect { term }.to raise_error 'Missing local_uri_host in config/uri_service.yml'
      end
    end

    it 'creates solr document' do
      expect(term_solr_doc).to include(
        'pref_label' => 'Dragons',
        'term_type' => 'local',
        'custom_fields' => '{"harry_potter_reference":true}'
      )
    end
  end

  describe 'when creating temporary term' do
    let(:term) { FactoryBot.create(:temp_term) }

    it 'sets temporary term uri' do
      expect(term.uri).to start_with 'temp:'
    end

    it 'sets uri_hash' do
      expect(term.uri_hash).not_to be blank?
    end

    it 'sets uuid' do
      expect(term.uuid).not_to be blank?
    end

    context 'when there is a temporary term for the label given' do
      let(:term_0) { FactoryBot.create(:temp_term) }
      let(:term) { FactoryBot.build(:temp_term, vocabulary: term_0.vocabulary) }

      it 'returns validation errors' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Uri has already been added to this vocabulary'
      end
    end

    it 'creates solr document' do
      expect(term_solr_doc).to include(
        'pref_label' => 'Yeti',
        'term_type' => 'temporary',
        'alt_label' => ['Big Foot'],
        'custom_fields' => '{"harry_potter_reference":false}'
      )
    end
  end

  describe 'when creating a term' do
    context 'with missing pref_label' do
      let(:term) { FactoryBot.build(:external_term, pref_label: nil) }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Pref label can\'t be blank'
      end
    end

    context 'with missing term_type' do
      let(:term) { FactoryBot.build(:external_term, term_type: nil) }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include('Term type can\'t be blank', 'Term type is not valid: ')
      end
    end

    context 'wtih invalid term_type' do
      let(:term) { FactoryBot.build(:external_term, term_type: 'not_valid') }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include('Term type is not valid: not_valid')
      end
    end

    context 'with invalid custom_field' do
      let(:term) { FactoryBot.build(:external_term, custom_fields: { 'fake_custom_field' => 'blahblahblah' }) }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Custom field fake_custom_field is not a valid custom field.'
      end
    end

    context 'with invalid uuid' do
      let(:term) { FactoryBot.build(:external_term, uuid: 'not-valid-at-all') }

      it 'returns validation error' do
        expect(term.save).to be false
        expect(term.errors.full_messages).to include 'Uuid is invalid'
      end
    end
  end

  describe 'when updating record' do
    let(:term) { FactoryBot.create(:external_term) }

    it 'cannot change uuid' do
      expect(term.update(uuid: 1234)).to be false
    end

    it 'cannot change term_type' do
      expect(term.update(term_type: 'local')).to be false
    end

    it 'cannot change uri' do
      expect(term.update(uri: 'https://example.com/term/fakes')).to be false
    end

    it 'updates solr document' do
      term.update(alt_label: ['new_label'])
      expect(term_solr_doc).to include('alt_label' => ['new_label'])
    end

    context 'of a temporary term' do
      let(:term) { FactoryBot.create(:temp_term) }

      it 'cannot change pref_label' do
        expect(term.update(pref_label: 'Big Foot')).to be false
      end
    end
  end

  describe 'when destroying a term' do
    let(:term) { FactoryBot.create(:external_term) }

    it 'deletes solr document' do
      expect(term_solr_doc).not_to be nil
      term.destroy
      expect(URIService.solr.find_term(term.vocabulary.string_key, term.uri)).to be nil
    end
  end
end
