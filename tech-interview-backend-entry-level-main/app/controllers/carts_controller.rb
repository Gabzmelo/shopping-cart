class CartsController < ApplicationController
  before_action :load_cart_manager

  # GET /cart
  def show
    render json: cart_response(@cart_manager.cart)
  end

  # POST /cart
  def create
    product_id = params[:product_id]
    quantity = params[:quantity].to_i

    if quantity <= 0
      return render json: { error: "Quantidade inválida" }, status: :unprocessable_entity
    end

    begin
      @cart = @cart_manager.add_product(product_id, quantity)
      render json: cart_response(@cart)
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /cart/add_item
  def add_item
    product_id = params[:product_id]
    quantity = params[:quantity].to_i

    if quantity <= 0
      return render json: { error: "Quantidade inválida" }, status: :unprocessable_entity
    end

    begin
      @cart = @cart_manager.update_quantity(product_id, quantity)
      render json: cart_response(@cart)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Produto não encontrado no carrinho" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # DELETE /cart/:product_id
  def destroy
    product_id = params[:product_id]

    begin
      @cart = @cart_manager.remove_product(product_id)
      render json: cart_response(@cart)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Produto não encontrado no carrinho" }, status: :not_found
    end
  end

  private

  def load_cart_manager
    @cart_manager = CartManager.new(session)
  end

  def cart_response(cart)
    {
      id: cart.id,
      products: cart.cart_items.includes(:product).map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.product.unit_price,
          total_price: item.total_price
        }
      end,
      total_price: cart.total_price
    }
  end
end
