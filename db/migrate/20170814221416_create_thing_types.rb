class CreateThingTypes < ActiveRecord::Migration
  def change
    create_table :thing_types do |t|
      t.references :thing, {index: true, foreign_key: true, null: false}
      t.references :type, {index: true, foreign_key: true, null: false}
      t.boolean :is_vip_pass_required

      t.timestamps null: false
    end
  end
end
