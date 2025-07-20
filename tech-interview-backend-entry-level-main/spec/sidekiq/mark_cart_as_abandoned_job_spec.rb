require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    it 'marks carts inactive for more than 3 hours as abandoned' do
      cart_inactive = create(:cart, last_interaction_at: 4.hours.ago, abandoned_at: nil)
      cart_active = create(:cart, last_interaction_at: 1.hour.ago, abandoned_at: nil)

      expect {
        MarkCartAsAbandonedJob.perform_async
      }.to change { cart_inactive.reload.abandoned_at }.from(nil).to(be_within(1.second).of(Time.current))
      expect(cart_active.reload.abandoned_at).to be_nil
    end

    it 'removes carts abandoned for more than 7 days' do
      old_abandoned_cart = create(:old_abandoned_cart, last_interaction_at: 8.days.ago)
      recently_abandoned_cart = create(:abandoned_cart, last_interaction_at: 4.days.ago)
      active_cart = create(:cart, last_interaction_at: 1.hour.ago, abandoned_at: nil)

      expect {
        MarkCartAsAbandonedJob.perform_async
      }.to change(Cart, :count).by(-1)

      expect(Cart.exists?(old_abandoned_cart.id)).to be_falsey
      expect(Cart.exists?(recently_abandoned_cart.id)).to be_truthy
      expect(Cart.exists?(active_cart.id)).to be_truthy
    end
  end
end
