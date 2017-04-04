FactoryGirl.define do
  factory :auction do
    association :user, factory: :admin_user
    billable_to "Project (billable)"
    started_at { quartile_minute(Time.now - 3.days) }
    ended_at { quartile_minute(Time.now + 3.days) }
    delivery_status :pending_delivery
    title { Faker::Company.catch_phrase }
    type :reverse
    published :published
    summary Faker::Lorem.paragraph
    description Faker::Lorem.paragraphs(3, true).join("\n\n")
    delivery_due_at { quartile_minute(Time.now + 10.days) }
    purchase_card :default

    transient do
      bidders []
    end

    after(:create) do |auction, evaluator|
      evaluator.bidders.each do |bidder|
        auction.bids << create(:bid, bidder: bidder, auction: auction)
      end
    end

    trait :with_bids do
      after(:build) do |auction|
        Timecop.freeze(auction.started_at) do
          Timecop.scale(3600)
          (1..2).each do |i|
            amount = 3499 - (20 * i) - rand(10)
            auction.bids << create(:bid, auction: auction, amount: amount)
          end
        end
      end
    end

    trait :published do
      c2_budget_approved
      published :published
    end

    trait :archived do
      published :archived
    end

    trait :unpublished do
      future
      published :unpublished
    end

    trait :sealed_bid do
      type :sealed_bid
    end

    trait :reverse do
      type :reverse
    end

    trait :between_micropurchase_and_sat_threshold do
      association :user, factory: :contracting_officer
      start_price do
        rand(AuctionThreshold::MICROPURCHASE + 1..AuctionThreshold::SAT)
      end
    end

    trait :below_micropurchase_threshold do
      start_price { rand(1..AuctionThreshold::MICROPURCHASE) }
    end

    trait :future do
      started_at { quartile_minute(Time.now + 2.days) }
    end

    trait :available do
      started_at { quartile_minute(Time.now - 2.days) }
      ended_at { quartile_minute(Time.now + 2.days) }
    end

    trait :expiring do
      ended_at { quartile_minute(Time.now + 3.hours) }
    end

    trait :closed do
      ended_at { quartile_minute(Time.now - 2.days) }
    end

    trait :delivery_url do
      delivery_url 'https://github.com/foo/bar'
    end

    trait :delivery_due_at_expired do
      delivery_due_at { quartile_minute(ended_at + 1.day) }
    end

    trait :pending_acceptance do
      closed
      delivery_status :pending_acceptance
    end

    trait :accepted do
      closed
      c2_budget_approved
      delivery_status :accepted
      accepted_at { Time.now }
    end

    trait :accepted_pending_payment_url do
      accepted
      c2_budget_approved
      with_bids
      delivery_url
      delivery_status :accepted_pending_payment_url
    end

    trait :work_in_progress do
      with_bids
      closed
      delivery_url
      delivery_status :work_in_progress
    end

    trait :rejected do
      closed
      c2_budget_approved
      delivery_status :rejected
      rejected_at { Time.now }
    end

    trait :paid do
      closed
      paid_at { Time.current }
    end

    trait :not_paid do
      paid_at nil
    end

    trait :payment_confirmed do
      closed
      c2_status :payment_confirmed
    end

    trait :winning_vendor_is_small_business do
      after(:create) do |auction|
        create(:bid, :from_small_business, auction: auction)
      end
    end

    trait :winning_vendor_is_non_small_business do
      after(:create) do |auction|
        create(:bid, :from_non_small_business, auction: auction)
      end
    end

    trait :pending_c2_approval do
      future
      c2_proposal_url 'https://c2-dev.18f.gov/proposals/2486'
      c2_status :pending_approval
      purchase_card :default
      unpublished
    end

    trait :c2_budget_approved do
      c2_proposal_url 'https://c2-dev.18f.gov/proposals/2486'
      c2_status :budget_approved
    end

    trait :evaluation_needed do
      closed
      c2_budget_approved
      with_bids
      delivery_url
      pending_acceptance
    end

    trait :payment_needed do
      closed
      with_bids
      delivery_url
      accepted
      not_paid
    end

    trait :complete_and_successful do
      closed
      with_bids
      delivery_url
      accepted
      paid
    end
  end
end
