class RenameRequestIdToPropertyIdInMitigations < ActiveRecord::Migration[8.0]
  def change
    rename_column :mitigations, :request_id, :property_id
  end
end
