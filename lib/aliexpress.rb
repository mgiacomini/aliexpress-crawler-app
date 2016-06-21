require 'aliexpress/crawler'
require 'aliexpress/links'
require 'aliexpress/woocommerce'

module Aliexpress
  class API
    def initialize url, consomer_key, consomer_secret, file
      #Inicializa WooCommerce com dados informados
      @woocommerce = Aliexpress::Woocommerce.new(url,consomer_key,consomer_secret)
      #Importa planilha com links, em caso de erro aborta a aplicação
      @links = links(file)
    rescue
      p "Erro ao importar planilha, favor verificar dados!"
      exit
    end

    #Pega os pedidos e manda para o crawler excutar o script
    def run user, password
      #Importando pedidos do Wordpress, aborta em caso de erro
      orders = @woocommerce.get_orders
      if orders.count == 0
        p "Não há pedidos a serem processados!"
        exit
      else
        p "Processando #{orders.count} pedidos!"
      end

      #Iniciando Crawler, aborta em caso de erro
      crawler = crawler orders, @links, @woocommerce

      #Rodando script, aborta em caso de erro
      crawler.run user, password
    rescue
        p "Erro ao iniciar script, verificar usuário e senha"
    end

    #Iniciando woocommerce com url, key e secret do wordpress
    def woocommerce url, consomer_key, consumer_secret
      Aliexpress::WooCommerce.new woocommerce
    end

    #Iniciando links com a planilha
    def links file
      Aliexpress::Links.new file
    end

    #Iniciando crawler com orders, links e woocommerce
    def crawler orders, links, woocommerce
      Aliexpress::Crawler.new orders, links, woocommerce
    end
  end
end
