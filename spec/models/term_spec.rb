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

    it 'return error when uri invalid' do
      expect {
        FactoryBot.create(:external_term, uri: 'ldfkja')
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'returns error if uri is missing' do
      expect { FactoryBot.create(:external_term, uri: '') }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'returns error if uri is already represented in vocabulary' do
      term
      expect { FactoryBot.create(:external_term) }.to raise_error ActiveRecord::RecordInvalid
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
      expect(term.uri).to start_with 'https://example.com/term/'
    end

    it 'sets uri_hash' do
      expect(term.uri_hash).not_to be blank?
    end

    it 'sets uuid' do
      expect(term.uuid).not_to be blank?
    end

    context 'when missing local_uri_host in config/uri_service.yml' do
      before do
        allow(Rails.application).to receive(:config_for).with(:uri_service).and_return({})
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

    it 'fails if there is a temporary term for the label given' do
      term
      expect { FactoryBot.create(:temp_term) }.to raise_error ActiveRecord::RecordInvalid
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
    it 'fails if pref_label missing' do
      expect {
        FactoryBot.create(:external_term, pref_label: nil)
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'fails if term_type missing' do
      expect {
        FactoryBot.create(:external_term, term_type: nil)
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'fails if term_type is invalid' do
      expect {
        FactoryBot.create(:external_term, term_type: 'not_valid')
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'fails if custom_field is invalid' do
      expect {
        FactoryBot.create(:external_term, custom_fields: { 'fake_custom_field' => 'blahblahblah' })
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it 'fails if uuid is invalid' do
      expect {
        FactoryBot.create(:external_term, uuid: 'not-valid-at-all')
      }.to raise_error ActiveRecord::RecordInvalid
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
