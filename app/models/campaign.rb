class Campaign < ApplicationRecord
  has_many :donations, dependent: :destroy

  before_validation :generate_slug, on: :create

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :goal_amount, numericality: { greater_than: 0 }

  def to_param
    slug
  end

  def raised_amount
    donations.countable.sum(:amount)
  end

  def progress_percentage
    return 0 if goal_amount.zero?

    ((raised_amount / goal_amount) * 100).clamp(0, 100).round(1)
  end

  def donations_count
    donations.countable.count
  end

  def youtube_video_id
    cover_image_url.to_s.match(%r{(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/))([^?&\s]+)})&.[](1)
  end

  private

  def generate_slug
    self.slug = title.to_s.parameterize if slug.blank?
  end
end
