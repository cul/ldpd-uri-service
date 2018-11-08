class CreateVocabularies < ActiveRecord::Migration[5.2]
  def change
    create_table :vocabularies do |t|
      t.string :label
      t.string :string_key, null: false

      t.timestamps
    end

    add_index :vocabularies, :string_key, unique: true
  end
end
