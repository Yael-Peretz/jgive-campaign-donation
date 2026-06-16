class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :campaign, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :frequency, null: false, default: 0
      t.integer :display_preference, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :donor_name, null: false
      t.text :dedication_message

      t.timestamps
    end
  end
end
