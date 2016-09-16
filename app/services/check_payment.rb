class CheckPayment < C2ApiWrapper
  def initialize(auctions = AuctionQuery.new.c2_payment_needed)
    @auctions = auctions
  end

  def perform
    auctions.each do |auction|
      paid_at = find_purchase_timestamp(proposal_json(auction))

      if paid_at
        auction.update(c2_status: :c2_paid, paid_at: DateTime.parse(paid_at))
        AuctionMailer.auction_paid_winning_vendor_notification(auction: auction).deliver_later
      end
    end
  end

  private

  attr_reader :auctions

  def find_purchase_timestamp(proposal_json)
    parsed_json = proposal_json.body
    purchase_step = parsed_json[:steps].detect do |step|
      step[:type] == "Steps::Purchase"
    end

    purchase_step[:completed_at]
  end
end
