require 'woocommerce_api'

class Wordpress < ActiveRecord::Base
  validates :name, :url, :consumer_key, :consumer_secret, presence: true
  has_many :crawlers, dependent: :destroy
  has_many :products, dependent: :destroy

  @error = nil

  def error
    @error
  end

  def woocommerce
    woocommerce = WooCommerce::API.new(
        self.url, #Url do site
        self.consumer_key, #Consumer Key
        self.consumer_secret, #Consumer Secret
        {
            wp_api: true,
            version: "wc/v2" #Versão da API
        }
    )
    woocommerce
  end

  def get_products
    all_products = []
    page = 1

    while true
      response = woocommerce.get("products?page=#{page}&per_page=100").parsed_response
      break if response.none?
      all_products.concat(response)
      page += 1
    end

    all_products
  end

  def get_product(id)
    woocommerce.get("products/#{id}").parsed_response
  end

  def update_order order, order_nos
    self.complete_order order
    self.update_note order, order_nos
  rescue
    @error = "Erro ao atualizar pedido #{order["id"]} no wordpress, verificar ultimo pedido na aliexpress."
  end

  def update_note order, ali_order_num
    #Atualiza pedidos no wordpress com o numero dos pedidos da aliexpress
    data = {note: ali_order_num}

    #POST em order notes
    woocommerce.post("orders/#{order["id"]}/notes", data).parsed_response
  end

  ## Add new wordpress note with tracking number for an order
  # *wordpress_reference* is the wordpress order id
  def update_tracking_number_note wordpress_reference, tracking_number
    #Atualiza o código de rastreio do pedido
    data = {note: "Código de rastreio: #{tracking_number}"}
    #POST em order notes
    woocommerce.post("orders/#{wordpress_reference}/notes", data).parsed_response
  end

  def complete_order order

    data = {status: "completed"}
    #PUT para mudar a ordem para concluída
    woocommerce.put("orders/#{order["id"]}", data).parsed_response
  end

  def get_orders amount = 200, page = 1, order = 'asc', status = 'processing'
    all_orders = []

    while true
      response = woocommerce.get("orders?page=#{page}&per_page=100&order=#{order}&status=#{status}").parsed_response
      break if response.none?
      all_orders.concat(response)
      break if all_orders.count >= amount
      page += 1
    end

    all_orders
  rescue
    @error = "Erro ao importar pedidos do Wordpress, favor verificar configurações."
  end

  def get_order order_id
    # This method only exists for debugging porpouses
    order = woocommerce.get("orders/#{order_id}").parsed_response
  end

  def get_notes order
    all_notes = woocommerce.get("orders/#{order["id"]}/notes").parsed_response
  end
end
