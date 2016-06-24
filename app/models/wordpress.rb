require 'woocommerce_api'

class Wordpress < ActiveRecord::Base
  validates :name, :url, :consumer_key, :consumer_secret, presence: true
  has_many :crawlers

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
        version: "v2" #Versão da API
      }
    )
    woocommerce
  end

  def get_products
    products = woocommerce.get("products?filter[limit]=1000&fields=id,permalink,title").parsed_response
    products['products']
  end

  def update_order order, order_nos
    #Atualiza pedidos no wordpress com o numero dos pedidos da aliexpress
    string = ""
    order_nos.each do |order_no|
      #Concatena os numeros de pedidos em uma mesma mensagem
      string.concat "#{order_no.text} "
    end
    data = {
      order_note: {
        note: string.strip
      }
    }
    #POST em order notes
    woocommerce.post("orders/#{order["id"]}/notes", data).parsed_response
    data = {
      order: {
        status: "completed"
      }
    }
    #PUT para mudar a ordem para concluída
    # @woocommerce.put("orders/#{order["id"]}", data).parsed_response
  rescue
    @error = "Erro ao atualizar pedido #{order["id"]} no wordpress, verificar ultimo pedido na aliexpress."
    exit
  end

  def get_orders
    #Pegar todos os pedidos com status Processado, limite 1000 e apenas dados
    #que serão usados: id,shipping_address,line_items
    all_orders = woocommerce.get("orders?filter[limit]=1000&status=processing&fields=id,shipping_address,line_items").parsed_response
    #Converção para array
    all_orders["orders"]
  rescue
    @error =  "Erro ao importar pedidos do Wordpress, favor verificar configurações."
    exit
  end
end
