class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: :cart_id, message: "já existe nesse carrinho" }

  before_validation :set_unit_price, on: :create
  after_save :update_cart_total_price
  after_destroy :update_cart_total_price

  def total_price
    quantity * unit_price
  end

  private

  def set_unit_price
    self.unit_price = product.price if product.present? && unit_price.nil?
  end

  def update_cart_total_price
    cart.update(total_price: cart.calculate_total_price)
  end
end