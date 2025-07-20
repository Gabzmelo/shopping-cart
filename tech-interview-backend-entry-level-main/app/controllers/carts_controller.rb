class CartsController < ApplicationController
  before_action :set_cart

  # POST /cart
  # Adiciona um produto ao carrinho ou define a quantidade se ele já existir.
  def add_product
    product = Product.find_by(id: params[:product_id])
    if product.nil?
      return render json: { error: "Product not found" }, status: :not_found
    end

    quantity = params[:quantity].to_i
    if quantity <= 0
      return render json: { error: "Quantity must be greater than zero" }, status: :unprocessable_entity
    end

    cart_item = @cart.cart_items.find_by(product_id: product.id)

    if cart_item
      # Se o item já existe, atualiza a quantidade para o valor informado.
      cart_item.update(quantity: quantity)
    else
      # Se não existe, cria um novo item.
      @cart.cart_items.create(product: product, quantity: quantity)
    end

    render json: formatted_cart_response, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # GET /cart
  # Lista os itens do carrinho atual.
  def show
    render json: formatted_cart_response, status: :ok
  end

  # POST /cart/add_item
  # Incrementa a quantidade de um produto no carrinho, ou o adiciona se não existir.
  def increment_item_quantity
    product = Product.find_by(id: params[:product_id])
    if product.nil?
      return render json: { error: "Produto não encontrado" }, status: :not_found
    end

    quantity_to_add = params[:quantity].to_i
    if quantity_to_add <= 0
      return render json: { error: "Quantidade inválida" }, status: :unprocessable_entity
    end

    cart_item = @cart.cart_items.find_by(product_id: product.id)

    if cart_item
      cart_item.increment!(:quantity, quantity_to_add) # Incrementa a quantidade
    else
      @cart.cart_items.create(product: product, quantity: quantity_to_add)
    end

    render json: formatted_cart_response, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /cart/:product_id
  # Remove um produto do carrinho.
  def remove_product
    product_id = params[:product_id]
    cart_item = @cart.cart_items.find_by(product_id: product_id)

    if cart_item
      cart_item.destroy
      render json: formatted_cart_response, status: :ok
    else
      render json: { error: "Produto não encontrado no carrinho" }, status: :not_found
    end
  end

  private

  def set_cart
    cart_id = session[:cart_id]
    @cart = Cart.find_by(id: cart_id)

    if @cart.nil?
      @cart = Cart.create(total_price: 0)
      session[:cart_id] = @cart.id
    end
  end

  def formatted_cart_response
    {
      id: @cart.id,
      products: @cart.cart_items.map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          total_price: item.total_price.to_f
        }
      end,
      total_price: @cart.total_price.to_f
    }
  end
end
