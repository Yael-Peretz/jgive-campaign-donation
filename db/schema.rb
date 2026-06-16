# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_16_174951) do
  create_table "campaigns", force: :cascade do |t|
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.decimal "goal_amount", precision: 10, scale: 2, null: false
    t.string "slug", null: false
    t.text "story"
    t.string "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_campaigns_on_slug", unique: true
  end

  create_table "donations", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "campaign_id", null: false
    t.datetime "created_at", null: false
    t.text "dedication_message"
    t.integer "display_preference", default: 0, null: false
    t.string "donor_name", null: false
    t.integer "frequency", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_donations_on_campaign_id"
  end

  add_foreign_key "donations", "campaigns"
end
