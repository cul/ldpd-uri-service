class ChangeAltLabelColumnName < ActiveRecord::Migration[5.2]
  def change
    rename_column :terms, :alt_label, :alt_labels
  end
end
