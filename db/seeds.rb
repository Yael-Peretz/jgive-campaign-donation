# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Guarded at the top level (rather than per-record find_or_create_by!) since donations have no
# natural unique key to dedupe on, and bin/docker-entrypoint runs this on every boot.
if Campaign.exists?
  puts "Seeds already applied, skipping."
  return
end

orange_garden = Campaign.create!(
  title: "The Orange Garden",
  summary: "Help us build the Orange Garden in Israel in memory of Shiri, Ariel, and Kfir Bibas, and all the children of October 7.",
  story: <<~STORY,
    From Pain, We Are Building Life
    A place where children will run again. Where families will heal. Where a nation turns pain into life. The land is ready. Now it's up to us 🧡

    The municipality of Migdal HaEmek has granted the land and committed to maintaining and protecting the garden. The plans are ready. All that's needed is you — to help transform this soil into a garden of life. Every contribution becomes something real: a tree rooted in the earth, a walking path, a corner of light and inspiration that will remain for generations.

    A Space for Healing, A Place for Everyone
    Designed with the principles of Nature Therapy and Zen healing, The Orange Garden is a bridge between memory and the future.

    • The Healing Garden: A specialized horticultural therapy space serving wounded veterans with PTSD and at-risk youth.
    • The Bibas Fruit Groves: Planting the citrus trees Ariel and Shiri loved most.
    • The "Water of Life" Stream: A flowing ecological stream inspired by Ariel's love for water.
    • The Children's Wishing Wall: A place where children can place their prayers and dreams.
    • Community & Culture: Outdoor classrooms, family picnic areas, and an amphitheater.

    "Every tree we plant is a victory. Every child's laughter in this garden is our resilience."

    We're starting with a goal of ₪5 million to build Phase 1 of the garden. From there, we will continue to Phase 2 to complete the full vision. Every contribution today helps bring the garden to life.
  STORY
  cover_image_url: "https://youtu.be/cNy3jf0lptw",
  goal_amount: 5_000_000
)

Donation.create!([
  {
    campaign: orange_garden, donor_name: "Yael Cohen", amount: 1_800,
    frequency: :one_time, display_preference: :full_name, status: :paid,
    dedication_message: "In memory of the Bibas family. Am Yisrael Chai."
  },
  {
    campaign: orange_garden, donor_name: "Daniel Smith", amount: 500,
    frequency: :monthly, display_preference: :full_name, status: :pending,
    dedication_message: "May this garden bring peace and healing."
  },
  {
    campaign: orange_garden, donor_name: "Anonymous", amount: 3_600,
    frequency: :one_time, display_preference: :anonymous, status: :paid
  },
  {
    campaign: orange_garden, donor_name: "Michal", amount: 180,
    frequency: :one_time, display_preference: :first_name_only, status: :paid,
    dedication_message: "Planting a tree for the future."
  },
  {
    campaign: orange_garden, donor_name: "Omer Levy", amount: 250,
    frequency: :monthly, display_preference: :full_name, status: :pending
  },
  {
    campaign: orange_garden, donor_name: "Anonymous", amount: 50,
    frequency: :one_time, display_preference: :anonymous, status: :paid
  }
])

puts "Seeded #{Campaign.count} campaign(s) and #{Donation.count} donations."
