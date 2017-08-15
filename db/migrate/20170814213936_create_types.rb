class CreateTypes < ActiveRecord::Migration
  def change
    create_table :types do |t|
      t.string :name, {null: false}
      t.string :notes

      t.timestamps null: false
    end
  end
end
