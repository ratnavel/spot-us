class Myspot::DonationAmountsController < ApplicationController

  before_filter :login_required, :except => [:show]
  helper_method :unpaid_donations, :unpaid_credits, :spotus_donation

  def show
    redirect_to :action => 'edit'
  end

  def edit
  end

  def update
    
    donation_amounts = params[:donation_amounts]
    credit_pitch_amounts = params[:credit_pitch_amounts]
    if donation_amounts
      @donations = Donation.update(donation_amounts.keys, donation_amounts.values)
    end
    
    if credit_pitch_amounts
        if current_user.has_enough_credits?(credit_pitch_amounts)
            @credit_pitches = Donation.update(credit_pitch_amounts.keys, credit_pitch_amounts.values)
        else
            flash[:error] = "You don't have sufficient credits"
        end
    end
    
    update_balance_cookie
    if params[:submit] == "update"
        redirect_to :back
    elsif @donations && @donations.all?{|d| d.valid? }
      spotus_donation.update_attribute(:amount, params[:spotus_donation_amount])
      redirect_to new_myspot_purchase_path
    else
      if @credit_pitches
          current_user.apply_credit_pitches
          flash[:notice] = "Credits applied"
      end
      redirect_to myspot_donations_path
    end
  end

  protected

  def unpaid_donations
    @unpaid_donations ||= current_user.donations.unpaid
  end
  
  def unpaid_credits
    @unpaid_credits ||= current_user.credit_pitches.unpaid
  end

  def spotus_donation
    @spotus_donation ||= current_user.current_spotus_donation
  end

end

                     