class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  has_and_belongs_to_many :products
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  accepts_nested_attributes_for :cart_items
  before_save :update_last_interaction_at

  def add_product(product, quantity)
    item = cart_items.find_or_initialize_by(product: product)
    item.quantity ||= 0
    item.quantity += quantity
    item.unit_price = product.price
    item.save!
  end

  def update_product_quantity(product, quantity)
    raise ArgumentError, "Quantidade não pode ser negativa" if quantity < 0

    item = cart_items.find_by(product: product)
    if item
      item.update!(quantity: quantity)
    else
      add_product(product, quantity)
    end
  end

  def remove_product(product)
    item = cart_items.find_by(product: product)
    item&.destroy
  end

  def total_price
    cart_items.sum(&:total_price)
  end

  def to_payload
    {
      id: id,
      products: cart_items.includes(:product).map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          total_price: item.total_price.to_f
        }
      end,
      total_price: total_price.to_f
    }
  end

  def calculate_total_price
    cart_items.sum(&:total_price)
  end

  def abandoned?
    abandoned_at.present?
  end

  # Lógica para marcar o carrinho como abandonado
  def mark_as_abandoned
    update(abandoned_at: Time.current) unless abandoned?
  end

  # Lógica para remover se abandonado por mais de 7 dias
  def self.remove_old_abandoned_carts
    where.not(abandoned_at: nil)
      .where('abandoned_at < ?', 7.days.ago)
      .destroy_all
  end

  private

  def update_last_interaction_at
    self.last_interaction_at = Time.current
  end
end
