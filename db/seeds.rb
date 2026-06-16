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

community_center = Campaign.create!(
  title: "Help Build a New Community Center",
  summary: "Building a vibrant new home for youth programs, family events, and community gatherings.",
  story: <<~STORY,
    For over a decade, our neighborhood has shared a single, aging hall for everything from after-school
    tutoring to holiday meals for seniors. It's no longer enough.

    We're raising funds to build a new community center with dedicated space for youth programs, a
    commercial kitchen for community meals, and a multi-purpose hall for events and celebrations.

    Every contribution, large or small, brings us closer to a space our whole community can finally call
    home.
  STORY
  cover_image_url: "seeds/community_center.svg",
  goal_amount: 50_000
)

winter_relief = Campaign.create!(
  title: "Winter Relief Fund for Families in Need",
  summary: "Providing warm clothing, heating assistance, and emergency food packages to families this winter.",
  story: <<~STORY,
    As temperatures drop, dozens of families in our community are forced to choose between heating their
    homes and putting food on the table.

    This fund provides emergency heating assistance, warm clothing, and grocery packages to families
    referred to us by local schools and social workers. Last winter, we helped over 80 families make it
    through the season safely.

    Your donation goes directly to families who need it most, with no overhead taken out.
  STORY
  cover_image_url: "seeds/winter_relief.svg",
  goal_amount: 20_000
)

Donation.create!([
  {
    campaign: community_center, donor_name: "David Levi", amount: 18_000,
    frequency: :one_time, display_preference: :full_name, status: :paid
  },
  {
    campaign: community_center, donor_name: "Rachel Goldberg", amount: 5_000,
    frequency: :monthly, display_preference: :full_name, status: :pending,
    dedication_message: "So proud to support this incredible project!"
  },
  {
    campaign: community_center, donor_name: "Tamar Friedman", amount: 1_200,
    frequency: :one_time, display_preference: :anonymous, status: :pending
  },
  {
    campaign: community_center, donor_name: "Yossi Mizrahi", amount: 500,
    frequency: :one_time, display_preference: :first_name_only, status: :pending,
    dedication_message: "Mazal tov on this wonderful initiative."
  },
  {
    campaign: community_center, donor_name: "Noa Shapiro", amount: 250,
    frequency: :monthly, display_preference: :full_name, status: :pending
  },
  {
    campaign: community_center, donor_name: "Avi Rosen", amount: 75,
    frequency: :one_time, display_preference: :anonymous, status: :pending
  },
  {
    campaign: winter_relief, donor_name: "Miriam Katz", amount: 3_000,
    frequency: :one_time, display_preference: :full_name, status: :paid,
    dedication_message: "In honor of my parents, refugees who once needed this kind of help."
  },
  {
    campaign: winter_relief, donor_name: "Eli Bergman", amount: 1_000,
    frequency: :monthly, display_preference: :full_name, status: :pending
  },
  {
    campaign: winter_relief, donor_name: "Dana Peretz", amount: 360,
    frequency: :one_time, display_preference: :anonymous, status: :pending,
    dedication_message: "Stay warm, stay strong."
  },
  {
    campaign: winter_relief, donor_name: "Jonathan Adler", amount: 180,
    frequency: :one_time, display_preference: :first_name_only, status: :pending
  },
  {
    campaign: winter_relief, donor_name: "Shira Weiss", amount: 50,
    frequency: :one_time, display_preference: :anonymous, status: :pending
  }
])

puts "Seeded #{Campaign.count} campaigns and #{Donation.count} donations."
