class BidsController < ApplicationController
  before_filter :require_authentication, except: [:index]
  skip_before_action :verify_authenticity_token, if: :api_request?

  def index
    auction = AuctionQuery.new.bids_index(params[:auction_id])
    @auction_bids = BidsIndexViewModel.new(auction: auction, current_user: current_user)
  end

  def my_bids
    bids = Bid.where(bidder: current_user).includes(:auction)
    @bids = bids.map { |bid| MyBidListItem.new(bid) }
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
    bid = PlaceBid.new(params: params, user: current_user, via: via)
    auction = Auction.find(params[:auction_id])

    if bid.valid?
      readonly_bid = bid.dry_run
      @confirm_bid = ConfirmBidViewModel.new(auction: auction, bid: readonly_bid)
    else
      flash[:error] = bid.errors
      redirect_to new_auction_bid_path(auction)
    end
  end

  def create
    @bid = PlaceBid.new(params: params, user: current_user, via: via)

    if @bid.perform
      respond_to do |format|
        format.html do
          flash[:bid] = "success"
          redirect_to auction_path(@bid.auction)
        end
        format.json { render json: @bid.bid, serializer: BidSerializer }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = @bid.errors
          redirect_to new_auction_bid_path(params[:auction_id])
        end
        format.json { render json: { error: @bid.errors }, status: 403 }
      end
    end
  end

  rescue_from 'ActiveRecord::RecordNotFound' do
    respond_to do |format|
      format.html do
        fail ActionController::RoutingError, 'Not Found'
      end
    end
  end
end
