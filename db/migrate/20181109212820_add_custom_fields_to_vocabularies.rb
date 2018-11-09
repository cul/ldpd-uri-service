class AddCustomFieldsToVocabularies < ActiveRecord::Migration[5.2]
  def change
    change_column_null :vocabularies, :label, false

    add_column :vocabularies, :custom_fields, :text
  end
end
