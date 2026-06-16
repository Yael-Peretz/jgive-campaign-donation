class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :summary
      t.text :story
      t.string :cover_image_url
      t.decimal :goal_amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :campaigns, :slug, unique: true
  end
end
