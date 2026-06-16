class CampaignsController < ApplicationController
  def index
    @campaigns = Campaign.all
  end

  def show
    @campaign = Campaign.find_by!(slug: params[:campaign_id])
    @donation = @campaign.donations.build
    @recent_donations = @campaign.donations.countable.recent
  end
end
