class AddIndexToThingTypes < ActiveRecord::Migration
  def change
    add_index :thing_types, [:thing_id, :type_id], unique:true
  end
end
