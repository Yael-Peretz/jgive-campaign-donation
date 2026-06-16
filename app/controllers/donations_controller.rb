class DonationsController < ApplicationController
  def create
    @campaign = Campaign.find_by!(slug: params[:campaign_id])
    @donation = @campaign.donations.build(donation_params)
    @donation.save
    @recent_donations = @campaign.donations.countable.recent

    respond_to do |format|
      if @donation.persisted?
        format.turbo_stream
        format.html { redirect_to @campaign, notice: "Thank you for your donation!" }
      else
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render "campaigns/show", status: :unprocessable_entity }
      end
    end
  end

  private

  def donation_params
    params.require(:donation).permit(:amount, :frequency, :display_preference, :donor_name, :dedication_message)
  end
end
