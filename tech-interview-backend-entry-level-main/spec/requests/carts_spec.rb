require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let(:product) { create(:product) }
  let(:cart) { create(:cart) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:session).and_return({ cart_id: cart.id })
  end

  describe "POST /cart - add_product" do
    context "with valid parameters" do
      it "adds a new product to the cart" do
        post add_product_to_cart_url, params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response["products"].first["id"]).to eq(product.id)
        expect(json_response["products"].first["quantity"]).to eq(1)
        expect(Cart.find(cart.id).cart_items.count).to eq(1)
      end

      it "updates quantity if product already in cart" do
        create(:cart_item, cart: cart, product: product, quantity: 2)
        post add_product_to_cart_url, params: { product_id: product.id, quantity: 5 }, as: :json
        expect(response).to have_http_status(:ok)
        expect(json_response["products"].first["quantity"]).to eq(5)
        expect(Cart.find(cart.id).cart_items.count).to eq(1)
      end

      it "updates cart total price" do
        post add_product_to_cart_url, params: { product_id: product.id, quantity: 1 }, as: :json
        expect(json_response["total_price"]).to eq(product.price.to_f)
      end
    end

    context "with invalid parameters" do
      it "returns error if product not found" do
        post add_product_to_cart_url, params: { product_id: 9999, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("Product not found")
      end

      it "returns error if quantity is zero or negative" do
        post add_product_to_cart_url, params: { product_id: product.id, quantity: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Quantity must be greater than zero")
      end
    end
  end

  describe "GET /cart - show" do
    it "lists items in the cart" do
      create(:cart_item, cart: cart, product: product, quantity: 3)
      get show_cart_url, as: :json
      expect(response).to be_successful
      expect(json_response["products"].count).to eq(1)
      expect(json_response["products"].first["id"]).to eq(product.id)
    end

    it "returns empty products array if cart is empty" do
      get show_cart_url, as: :json
      expect(response).to be_successful
      expect(json_response["products"]).to be_empty
      expect(json_response["total_price"]).to eq(0.0)
    end
  end

  describe "POST /cart/add_item - increment_item_quantity" do
    context 'when the product already is in the cart' do
      let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 1) }

      it 'increments the quantity of the existing item in the cart' do
        post increment_cart_item_quantity_url, params: { product_id: product.id, quantity: 2 }, as: :json
        expect(response).to have_http_status(:ok)
        expect(cart_item.reload.quantity).to eq(3) # 1 (initial) + 2 (added)
      end
    end

    context 'when the product is not in the cart' do
      it 'adds the product to the cart with the given quantity' do
        expect {
          post increment_cart_item_quantity_url, params: { product_id: product.id, quantity: 2 }, as: :json
        }.to change(cart.cart_items, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(json_response["products"].first["id"]).to eq(product.id)
        expect(json_response["products"].first["quantity"]).to eq(2)
      end
    end

    context "with invalid parameters" do
      it "returns error if product not found" do
        post increment_cart_item_quantity_url, params: { product_id: 9999, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("Product not found")
      end

      it "returns error if quantity to add is zero or negative" do
        post increment_cart_item_quantity_url, params: { product_id: product.id, quantity: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("Quantity to add must be greater than zero")
      end
    end
  end


  describe "DELETE /cart/:product_id - remove_product" do
    it "removes a product from the cart" do
      create(:cart_item, cart: cart, product: product, quantity: 1)
      expect {
        delete remove_product_from_cart_url(product_id: product.id), as: :json
      }.to change(cart.cart_items, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(json_response["products"]).to be_empty
    end

    it "returns error if product not found in cart" do
      delete remove_product_from_cart_url(product_id: product.id), as: :json
      expect(response).to have_http_status(:not_found)
      expect(json_response["error"]).to eq("Product not found in cart")
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
