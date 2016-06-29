require "watir-webdriver"
class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
  validates :aliexpress_id, :wordpress_id, presence: true
  has_many :crawler_logs
  # @log = nil
  # @error = nil

  def run(orders)
  # def run
    # order = self.wordpress.woocommerce.get("orders/88752").parsed_response
    # order = order['order']
    @log = CrawlerLog.create!(crawler: self)
    @log.update(orders_count: orders.count)
    raise "Não há pedidos a serem executados" if orders.count == 0
    raise "Falha no login, verifique as informações de configuração aliexpress ou tente novamente mais tarde" unless self.login
    orders.each do |order|
      @error = nil
      begin
        self.empty_cart #Esvazia Carrinho
        @log.add_message("-------------------")
        @log.add_message("Processando pedido ##{order['id']}")
        p "Processando pedido ##{order['id']}"
        customer = order["shipping_address"] #Loop para todos os produtos
        order["line_items"].each do |item|
          begin
            quantity = item["quantity"]
            product = Product.find_by_name(item["name"])
            if (meta = item["meta"]).empty?
              product_type = ProductType.find_by_product_id(product.id)
            else
              product_type = ProductType.find_by(product: product, name: meta[0]['value'])
            end
            raise if product_type.aliexpress_link.nil?
            @b.goto product_type.aliexpress_link #Abre link do produto
            stock = @b.dl(id: "j-product-quantity-info").when_present.text.split[2].gsub("(","").to_i
            if quantity > stock #Verifica estoque
              @error =  "Erro de estoque, produto #{item["name"]} não disponível na aliexpress!"
              @log.add_message(@error)
              p @error
              break
            else
              #Ações dos produtos
              p "Adicionando #{quantity} ao carrinho"
              self.add_quantity quantity
              p 'Selecionando opções'
              user_options = [product_type.option_1,product_type.option_3,product_type.option_3]
              self.set_options user_options
              # self.set_shipping @b, user_options
              p 'Adicionando ao carrinho'
              self.add_to_cart
            end
          rescue
            @error = "Erro no produto #{item["name"]}, verificar se o link da aliexpress está correto, este pedido será pulado."
            @log.add_message(@error)
            p @error
            break
          end
        end
        #Finaliza pedido
        if @error.nil?
          order_nos = self.complete_order(customer)
          p "Pedido completado"
          p order_nos.text
          raise if order_nos.nil? || !@erros.nil?
          self.wordpress.update_order(order, order_nos)
          @error = self.wordpress.error
          @log.add_message(@error)
          p @error
          @log.add_processed("Pedido #{order["id"]} processado com sucesso!")
          p "Pedido #{order["id"]} processado com sucesso!"
        else
          raise
        end
      rescue
        @error = "Erro ao concluir pedido #{order["id"]}, verificar aliexpress e wordpress."
        @log.add_message(@error)
        p @error
        next
      end
    end
  @b.close
  rescue
    @error = "Erro desconhecido, procurar administrador."
    @log.add_message(@error)
    p @error
  rescue => e
    @error = e.message
    @log.add_message(@error)
    p @error
  end


  #Efetua login no site da Aliexpresss usando user e password
  def login
    @log.add_message("Efetuando login com #{self.aliexpress.email}")
    p "Efetuando login com #{self.aliexpress.email}"
    @b = Watir::Browser.new :phantomjs
    user = self.aliexpress
    @b.goto "https://login.aliexpress.com/"
    frame = @b.iframe(id: 'alibaba-login-box')
    frame.text_field(name: 'loginId').set user.email
    frame.text_field(name: 'password').set user.password
    frame.button(name: 'submit-btn').click
    frame.wait_while_present
    true
  rescue
    false
  end
  #Adiciona item ao carrinho
  def add_to_cart
    @b.link(id: "j-add-cart-btn").click
    sleep 5
  end

  #Adiciona quantidade certa do item
  def add_quantity quantity
    (quantity -1).times do
      @b.dl(id: "j-product-quantity-info").i(class: "p-quantity-increase").when_present.click
    end
  end

  #Selecionar opções do produto na Aliexpress usando array de opções da planilha
  def set_options user_option
    count = 0
    @b.div(id: "j-product-info-sku").dls.each do |option|
      selected = user_option[count]
      if selected.nil?
        option.a.when_present.click
      else
        option.as[selected].when_present.click
      end
      count +=1
    end
  end

  #finaliza pedido com informações do cliente
  def complete_order customer
    @b.goto 'https://m.aliexpress.com/shopcart/detail.htm'
    @b.div(class: "buyall").when_present.click
    @b.a(id: "change-address").when_present.click
    @b.a(id: "manageAddressHref").when_present.click
    #Preenche campos de endereço
    @log.add_message('Adicionando informações do cliente')
    @b.text_field(name: "_fmh.m._0.c").when_present.set to_english(customer["first_name"]+" "+customer["last_name"])
    @b.divs(class: "panel-select")[0].click
    @b.li(text: "Brazil").when_present.click
    @b.text_field(name: "_fmh.m._0.a").set to_english(customer["address_1"])
    @b.text_field(name: "_fmh.m._0.ad").set to_english(customer["address_2"])
    @b.divs(class: "panel-select")[2].click
    arr = self.state.assoc(customer["state"])
    sleep 2
    @b.li(text: arr[1]).when_present.click
    @b.text_field(name: "_fmh.m._0.ci").set to_english(customer["city"])
    @b.text_field(name: "_fmh.m._0.z").set customer["postcode"]
    @b.text_field(name: "_fmh.m._0.m").set '11959642036'
    @b.button.click
    p 'Salvando'
  #   captcha = @b.div(class: "captcha-box")
  #   @log.add_message("Encontrei captcha ao finalizar o pedido!") if captcha.present?
    @b.button(id: "create-order").when_present.click #Botão Finalizar pedido
    p 'Finalizando Pedido'
    @b.div(class:"desc_txt").wait_until_present
    @b.div(class:"desc_txt")
  end

  #Tabela de conversão de Estados
  def state
    [
      ["AC","Acre"],
      ["AL","Alagoas"],
      ["AP","Amapa"],
      ["AM","Amazonas"],
      ["BA","Bahia"],
      ["CE","Ceara"],
      ["DF","Distrito Federal"],
      ["ES","Espirito Santo"],
      ["GO","Goias"],
      ["MA","Maranhao"],
      ["MT","Mato Grosso"],
      ["MS","Mato Grosso do Sul"],
      ["MG","Minas Gerais"],
      ["PA","Para"],
      ["PB","Paraiba"],
      ["PR","Parana"],
      ["PE","Pernambuco"],
      ["PI","Piaui"],
      ["RJ","Rio de Janeiro"],
      ["RN","Rio Grande do Norte"],
      ["RS","Rio Grande do Sul"],
      ["RO","Rondonia"],
      ["RR","Roraima"],
      ["SC","Santa Catarina"],
      ["SP","Sao Paulo"],
      ["SE","Sergipe"],
      ["TO","Tocantins"],
    ]
  end

  #Retira acentos e caracteres especiais
  def to_english string
    string.tr("ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž", "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
          .tr("^A-Za-z0-9 ", '')
  end

  #Esvazia carrinho
  def empty_cart
    p 'Esvaziando carrinho'
    @b.goto 'https://m.aliexpress.com/shopcart/detail.htm'
    if @b.li(id: "shopcart-").present?
      @b.lis(id: "shopcart-").each do |item|
        item.i(class: "ic-delete-md").when_present.click
        @b.div(class: "ok").when_present.click
      end
    end
  rescue
    @error = "Falha ao esvaziar carrinho, verificar conexão. Abortando para evitar falhas"
    @log.add_message(@error)
    p @error
    # exit
  end
end
