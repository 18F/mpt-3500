class BidsController < ApplicationController
  before_filter :require_authentication, except: [:index]
  skip_before_action :verify_authenticity_token, if: :api_request?

  def index
    auction = AuctionQuery.new
                          .with_bids_and_bidders
                          .published
                          .find(params[:auction_id])
    @auction = AuctionViewModel.new(current_user, auction)
  end

  def my_bids
    @bids = Bid
            .where(bidder_id: current_user.id)
            .includes(:auction)
            .all
            .map { |bid| BidPresenter.new(bid) }
  end

  def new
    if current_user.sam_accepted?
      auction = AuctionQuery.new.public_find(params[:auction_id])
      @bid_view_model = NewBidViewModel.new(auction: auction, current_user: current_user)
    else
      session[:return_to] = request.fullpath
      redirect_to users_edit_path
    end
  end

  def confirm
    bid = PlaceBid.new(params: params, user: current_user, via: via).dry_run
    @confirm_bid = ConfirmBidViewModel.new(auction: Auction.find(params[:auction_id]), bid: bid)
  end

  def create
    unless current_user.sam_accepted?
      fail UnauthorizedError, "You must have a valid SAM.gov account to place a bid"
    end
    @bid = BidPresenter.new(PlaceBid.new(params: params, user: current_user, via: via).perform)

    respond_to do |format|
      format.html do
        flash[:bid] = "success"
        redirect_to "/auctions/#{params[:auction_id]}"
      end
      format.json do
        render json: @bid, serializer: BidSerializer
      end
    end
  rescue UnauthorizedError => e
    respond_error(e, redirect_path: "/auctions/#{params[:auction_id]}/bids/new")
  end

  rescue_from 'ActiveRecord::RecordNotFound' do
    respond_to do |format|
      format.html do
        fail ActionController::RoutingError, 'Not Found'
      end
    end
  end

  private

  def respond_error(error, redirect_path: '/')
    respond_to do |format|
      format.html do
        flash[:error] = error.message
        redirect_to redirect_path
      end
      format.json do
        render json: { error: error.message }, status: 403
      end
    end
  end
end
