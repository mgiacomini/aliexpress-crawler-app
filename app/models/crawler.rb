require "watir-webdriver"
class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
  validates :aliexpress_id, :wordpress_id, presence: true
  has_many :crawler_logs

  def run(orders)
  # def run
    # order = self.wordpress.woocommerce.get("orders/93696")['order']
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
        customer = order["shipping_address"] #Loop para todos os produtos
          order["line_items"].each do |item|
            begin
              quantity = item["quantity"]
              product = Product.find_by_name(item["name"])
              if (meta = item["meta"]).empty?
                product_type = ProductType.find_by(product: product)
              else
                name = ""
                item["meta"].each do |option|
                  name.concat("#{option['value']} ")
                end
                product_type = ProductType.find_by(product: product, name: name.strip)
              end
              raise if product_type.aliexpress_link.nil?
              @b.goto product_type.parsed_link #Abre link do produto
              p 'Selecionando opções'
              user_options = [product_type.option_1,product_type.option_2 ,product_type.option_3]
              self.set_options user_options
              stock = @b.dl(id: "j-product-quantity-info").text.split[2].gsub("(","").to_i
              if quantity > stock #Verifica estoque
                @error =  "Erro de estoque, produto #{item["name"]} não disponível na aliexpress!"
                @log.add_message(@error)
                break
              else
                #Ações dos produtos
                p "Adicionando #{quantity} ao carrinho"
                self.add_quantity quantity
                # self.set_shipping @b, user_options
                p 'Adicionando ao carrinho'
                self.add_to_cart
                product_type.update(product_errors: 0)
              end
            rescue
              @error = "Erro no produto #{item["name"]}, verificar se o link da aliexpress está correto, este pedido será pulado."
              @log.add_message(@error)
              product_type.add_error
              break
            end
          end
        #Finaliza pedido
        if @error.nil?
          @b.goto 'https://m.aliexpress.com/shopcart/detail.htm'
          raise "Erro com itens do carrinho, cancelando pedido" if @b.lis(id: "shopcart-").count != order["line_items"].count
          order_nos = self.complete_order(customer)
          raise if !@error.nil?
          @log.add_message("Pedido completado na Aliexpress")
          raise "Erro com numero do pedido vazio" if order_nos.nil?
          self.wordpress.update_order(order, order_nos)
          @error = self.wordpress.error
          @log.add_message(@error)
          @log.add_processed("Pedido #{order["id"]} processado com sucesso! Links aliexpress: #{order_nos.text}")
        else
          raise
        end
      rescue
        @error = "Erro ao concluir pedido #{order["id"]}, verificar aliexpress e wordpress."
        @log.add_message(@error)
        next
      rescue => e
        @error = e.message
        @log.add_message(@error)
      end
    end
  @b.close
  rescue
    @error = "Erro desconhecido, procurar administrador."
    @log.add_message(@error)
  rescue => e
    @error = e.message
    @log.add_message(@error)
  end


  #Efetua login no site da Aliexpresss usando user e password
  def login
    @log.add_message("Efetuando login com #{self.aliexpress.email}")
    @b = Watir::Browser.new :phantomjs
    Watir.default_timeout = 90
    @b.window.maximize
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
    sleep 5
    @b.link(id: "j-add-cart-btn").when_present.click
    sleep 5
    if @b.div(class: "ui-add-shopcart-dialog").present?
      p "Adicionado OK"
    else
      @error = "Falha ao adicionar ao carrinho: #{@b.url}"
      @log.add_message(@error)
    end
  end

  #Adiciona quantidade certa do item
  def add_quantity quantity
    (quantity -1).times do
      @b.dl(id: "j-product-quantity-info").i(class: "p-quantity-increase").when_present.click
    end
  end

  #Selecionar opções do produto na Aliexpress usando array de opções da planilha
  def set_options user_options
    @b.div(id: "j-product-info-sku").dls.each_with_index do |option, index|
      selected = user_options[index]
      if selected.nil?
        option.a.when_present.click
      else
        option.as[selected-1].when_present.click
      end
    end
    sleep 5
  end

  def add_to_cart_mobile
    if @b.a(class: "back").present?
      @b.a(class: "back").click
      @b.button.when_present.click
    else
      @b.buttons[2].click
    end
    sleep 5
  end

  #Adiciona quantidade certa do item
  def add_quantity_mobile quantity
    (quantity -1).times do
      @b.a(class:"ms-plus").when_present.click
    end
  end

  #Selecionar opções do produto na Aliexpress usando array de opções da planilha
  def set_options_mobile user_options
    sleep 5
    @b.divs(class: "ms-sku-props").each_with_index do |option, index|
      selected = user_options[index]
      if option.img.present? && selected.nil?
        option.img.when_present.click
      elsif option.img.present?
        option.imgs[selected-1].when_present.click
      elsif selected.nil?
        option.span.when_present.click
      else
        option.spans[selected-1].when_present.click
      end
    end
    sleep 5
  end


  #finaliza pedido com informações do cliente
  def complete_order customer
    @b.div(class: "buyall").when_present.click
    @b.a(id: "change-address").when_present.click
    @b.a(id: "manageAddressHref").when_present.click
    #Preenche campos de endereço
    @log.add_message('Adicionando informações do cliente')
    @b.text_field(name: "_fmh.m._0.c").when_present.set to_english(customer["first_name"]+" "+customer["last_name"])
    @b.divs(class: "panel-select")[0].when_present.click
    sleep 5
    @b.li(text: "Brazil").when_present.click
    @b.text_field(name: "_fmh.m._0.a").when_present.set to_english(customer["address_1"]+" "+customer['number'])
    @b.text_field(name: "_fmh.m._0.ad").when_present.set to_english(customer["address_2"])
    @b.divs(class: "panel-select")[2].when_present.click
    arr = self.state.assoc(customer["state"])
    sleep 5
    @b.li(text: arr[1]).when_present.click
    @b.text_field(name: "_fmh.m._0.ci").when_present.set to_english(customer["city"])
    @b.text_field(name: "_fmh.m._0.z").when_present.set customer["postcode"]
    @b.text_field(name: "_fmh.m._0.m").when_present.set '11959642036'
    @b.button.click
    p 'Salvando'
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
    @b.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
    empty = @b.link(class: "remove-all-product")
    if empty.present?
      empty.click
      @b.div(class: "ui-window-btn").button.when_present.click
      empty.wait_while_present
    end
  rescue
    @error = "Falha ao esvaziar carrinho, verificar conexão."
    @log.add_message(@error)
    exit
  end
end
