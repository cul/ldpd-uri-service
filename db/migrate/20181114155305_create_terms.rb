class CreateTerms < ActiveRecord::Migration[5.2]
  def change
    create_table :terms do |t|
      t.belongs_to :vocabulary, index: true, null: false

      t.string :pref_label, null: false
      t.text   :alt_label
      t.string :uri,        null: false
      t.string :uri_hash,   null: false
      t.string :authority
      t.string :term_type,  null: false
      t.text   :custom_fields
      t.string :uuid,       null: false

      t.timestamps
    end

    add_index :terms, :uuid, unique: true
    add_index :terms, [:uri_hash, :vocabulary_id], unique: true
  end
end
