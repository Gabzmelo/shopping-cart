require 'rails_helper'

RSpec.describe "Cart API", type: :request do
  let(:product) { create(:product) }

  it "adiciona um produto ao carrinho" do
    post "/cart", params: { product_id: product.id, quantity: 2 }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["products"].first["quantity"]).to eq(2)
  end

  it "lista os itens do carrinho" do
    post "/cart", params: { product_id: product.id, quantity: 1 }
    get "/cart"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["products"].size).to be > 0
  end

  it "altera a quantidade de um item existente" do
    post "/cart", params: { product_id: product.id, quantity: 1 }
    post "/cart/add_item", params: { product_id: product.id, quantity: 3 }
    get "/cart"
    expect(JSON.parse(response.body)["products"].first["quantity"]).to eq(3)
  end

  it "remove um produto do carrinho" do
    post "/cart", params: { product_id: product.id, quantity: 1 }
    delete "/cart/#{product.id}"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["products"]).to be_empty
  end
end
