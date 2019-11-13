class AddLockedToVocabularies < ActiveRecord::Migration[5.2]
  def change
    add_column :vocabularies, :locked, :boolean, default: false
  end
end
