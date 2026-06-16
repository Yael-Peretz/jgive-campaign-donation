class Donation < ApplicationRecord
  belongs_to :campaign

  enum :frequency, { one_time: 0, monthly: 1 }, default: :one_time
  enum :display_preference, { full_name: 0, first_name_only: 1, anonymous: 2 }, default: :full_name
  # Only :pending and :paid exist for now (no payment provider is wired up yet), but the enum
  # leaves room for a future :failed/:refunded without touching the `countable` scope below.
  enum :status, { pending: 0, paid: 1 }, default: :pending

  validates :donor_name, presence: true, unless: :anonymous?
  validates :amount, numericality: { greater_than: 0 }

  # Pending donations count toward a campaign's progress today since there's no payment flow to
  # ever produce a paid one. Once a real provider is wired in, narrowing this to `where(status: :paid)`
  # is the only change needed to make progress reflect real money.
  scope :countable, -> { where(status: [ :pending, :paid ]) }
  scope :recent, -> { order(created_at: :desc) }

  def display_name
    case display_preference
    when "anonymous" then "Anonymous"
    when "first_name_only" then donor_name.to_s.split.first
    else donor_name
    end
  end
end
