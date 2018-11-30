require 'rails_helper'

RSpec.describe Vocabulary, type: :model do
  describe 'when creating a vocabulary' do
    context 'with a string key containing an invalid character' do
      let(:vocabulary) { FactoryBot.build(:vocabulary, string_key: 'mythical-creatures') }

      it 'returns validation error' do
        expect(vocabulary.save).to be false
      end
    end

    context 'with a string key that starts with a number' do
      let(:vocabulary) { FactoryBot.build(:vocabulary, string_key: '123mythical_creatures') }

      it 'returns validation error' do
        expect(vocabulary.save).to be false
      end
    end

    context 'with a string key that contains uppercase letters' do
      let(:vocabulary) { FactoryBot.build(:vocabulary, string_key: 'Mythical_Creatures') }

      it 'returns validation error' do
        expect(vocabulary.save).to be false
      end
    end

    context 'when missing label' do
      let(:vocabulary) { FactoryBot.build(:vocabulary, label: '') }

      it 'returns validation error' do
        expect(vocabulary.save).to be false
      end
    end

    context 'when missing string_key' do
      let(:vocabulary) { FactoryBot.build(:vocabulary, string_key: '') }

      it 'returns validation error' do
        expect(vocabulary.save).to be false
      end
    end
  end
end
