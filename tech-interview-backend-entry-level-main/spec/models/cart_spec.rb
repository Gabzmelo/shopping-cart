require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe '#mark_as_abandoned' do
    let(:cart) { create(:cart, last_interaction_at: 4.hours.ago, abandoned_at: nil) }

    it 'marks the cart as abandoned if inactive for more than 3 hours' do
      expect { cart.mark_as_abandoned }.to change(cart, :abandoned_at).from(nil).to(be_within(1.second).of(Time.current))
    end

    it 'does not mark as abandoned if already abandoned' do
      cart.update(abandoned_at: 1.day.ago)
      expect { cart.mark_as_abandoned }.not_to change(cart, :abandoned_at)
    end
  end

  describe '.remove_old_abandoned_carts' do
    it 'removes carts abandoned for more than 7 days' do
      create(:old_abandoned_cart, last_interaction_at: 8.days.ago) # Carts abandoned more than 7 days ago
      create(:abandoned_cart) # Carts abandoned less than 7 days ago
      create(:cart) # Not abandoned

      expect {
        Cart.remove_old_abandoned_carts
      }.to change(Cart, :count).by(-1)
    end

    it 'does not remove recently abandoned carts' do
      create(:abandoned_cart) # Carts abandoned less than 7 days ago
      expect {
        Cart.remove_old_abandoned_carts
      }.not_to change(Cart, :count)
    end
  end

  describe '#calculate_total_price' do
    let(:cart) { create(:cart) }
    let(:product1) { create(:product, price: 10.0) }
    let(:product2) { create(:product, price: 5.0) }

    before do
      create(:cart_item, cart: cart, product: product1, quantity: 2)
      create(:cart_item, cart: cart, product: product2, quantity: 3)
    end

    it 'calculates the correct total price of the cart' do
      expect(cart.calculate_total_price).to eq(2 * 10.0 + 3 * 5.0)
    end
  end
end
