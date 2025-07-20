class CartManager
  def initialize(session)
    @session = session
    @cart = find_or_create_cart
  end

  def cart
    @cart
  end

  def add_product(product_id, quantity)
    product = Product.find(product_id)
    @cart.add_product(product, quantity)
    schedule_abandonment_job
    @cart
  end

  def update_quantity(product_id, quantity)
    product = Product.find(product_id)
    @cart.update_product_quantity(product, quantity)
    @cart
  end

  def remove_product(product_id)
    product = Product.find(product_id)
    @cart.remove_product(product)
    @cart
  end

  private

  def find_or_create_cart
    Cart.find_or_create_by(id: @session[:cart_id]).tap do |cart|
      @session[:cart_id] = cart.id
    end
  end

  def schedule_abandonment_job
    MarkCartAsAbandonedJob.set(wait: 2.hours).perform_later(@cart.id)
  end
end
