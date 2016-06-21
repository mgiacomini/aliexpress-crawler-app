require 'woocommerce_api'

module Aliexpress
  class Woocommerce
    def initialize url, consumer_key, consumer_secret
      @woocommerce = WooCommerce::API.new(
        url, #Url do site
        consumer_key, #Consumer Key
        consumer_secret, #Consumer Secret
        {
          version: "v2" #Versão da API
        }
      )
    end

    #Retorna o link do produto da planilha, usando o id do produto
    def get_product_link product_id
      #Obtém do wordpress o link(permalink) de um produto pelo seu id
      product = @woocommerce.get("products/#{product_id}?fields=permalink").parsed_response
      #Converte o resultado para string
      product.first[1]["permalink"]
    rescue
      p "Erro ao pegar link do produto, verificar planilha."
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
      @woocommerce.post("orders/#{order["id"]}/notes", data).parsed_response
      data = {
        order: {
          status: "completed"
        }
      }
      #PUT para mudar a ordem para concluída
      @woocommerce.put("orders/#{order["id"]}", data).parsed_response
    rescue
      p "Erro ao atualizar pedido #{order["id"]} no wordpress, verificar ultimo pedido na aliexpress."
      exit
    end

    def get_orders
      #Pegar todos os pedidos com status Processado, limite 1000 e apenas dados
      #que serão usados: id,shipping_address,line_items
      all_orders = @woocommerce.get("orders?filter[limit]=1000&status=processing&fields=id,shipping_address,line_items").parsed_response
      #Converção para array
      all_orders["orders"]
    rescue
      p "Erro ao importar pedidos do Wordpress, favor verificar configurações."
      exit
    end
  end
end
