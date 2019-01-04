FactoryBot.define do
  factory :term do
    association :vocabulary, custom_fields: {
      harry_potter_reference: {
        label: 'Harry Potter Reference',
        data_type: 'boolean'
      }
    }

    factory :external_term do
      pref_label { 'Unicorns' }
      uri        { 'http://id.worldcat.org/fast/1161301/' }
      authority  { 'fast' }
      term_type  { 'external' }
      custom_fields {
        { harry_potter_reference: true }
      }
    end

    factory :local_term do
      pref_label { 'Dragons' }
      term_type  { 'local' }
      custom_fields {
        { harry_potter_reference: true }
      }
    end

    factory :temp_term do
      pref_label { 'Yeti' }
      term_type { 'temporary' }
      custom_fields {
        { harry_potter_reference: false }
      }
    end
  end
end
