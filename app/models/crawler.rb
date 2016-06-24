require "watir-webdriver"
class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
  validates :aliexpress_id, :wordpress_id, presence: true

  @error = nil
  @processed = []

  def error
    @error
  end

  def processed
    @processed
  end

  def run(orders)
    @b = self.login
    raise login_error if @b.nil?
    orders.each do |order|
      begin
        self.empty_cart @b #Esvazia Carrinho
        p order['id']
        customer = order["shipping_address"] #Loop para todos os produtos
        order["line_items"].each do |item|
          begin
            quantity = item["quantity"]
            product = Product.find_by_wordpress_id(item["product_id"])
            p product['name']
            @b.goto product.aliexpress_link #Abre link do produto
            raise product if product.aliexpress_link.nil?
            stock = @b.dl(id: "j-product-quantity-info").text.split[2].gsub("(","").to_i
            if quantity > stock #Verifica estoque
              @error =  'Erro de estoque, produto não disponível!'
              break
            else
              #Ações dos produtos
              p 'Adicionando quantidade'
              self.add_quantity @b, quantity
              p 'Selecionando opções'
              user_options = [product.option_1,product.option_3,product.option_3]
              self.set_options @b, user_options
              # self.set_shipping @b, user_options
              p 'Adicionando ao carrinho'
              self.add_to_cart @b
            end
          rescue
            @error = "Erro no produto #{item["name"]}, verificar link do produto na aliexpress, este pedido será pulado."
            break
            p @error
          end
        end
        #Finaliza pedido
        unless @error.nil?
          order_nos = self.complete_order(@b,customer)
          p "Pedido completado"
          raise if order_nos.count == 0
          self.wordpress.update_order(order, order_nos)
          @error = self.wordpress.error
          @processed << order["id"] if @error.nil?
        end
      rescue
        @error = "Erro ao concluir pedido #{order["id"]}, verificar aliexpress e wordpress."
        next
        p @error
      end
    end
  @b.close
  rescue => login_error
    @error = "Falha no login, verifique as informações ou tente novamente mais tarde"
    p "Falha no login, verifique as informações ou tente novamente mais tarde"
    exit
  rescue
    @error = "Erro desconhecido"
  end

  #Efetua login no site da Aliexpresss usando user e password
  def login
    p 'Efetuando login'
    @b = Watir::Browser.new :phantomjs
    user = self.aliexpress
    @b.goto "https://login.aliexpress.com/"
    frame = @b.iframe(id: 'alibaba-login-box')
    frame.text_field(name: 'loginId').set user.email
    frame.text_field(name: 'password').set user.password
    frame.button(name: 'submit-btn').click
    sleep 5
    #Levanta erro caso o login falhe (caso de captchas)
    # raise unless @b.span(class: "account-name").present? || @b.div(id: "account-name").present?
    @error = "Executado com sucesso"
    @b
  rescue
  end

  #Adiciona item ao carrinho
  def add_to_cart browser
    browser.link(id: "j-add-cart-btn").click
    sleep 10
  end

  #Adiciona quantidade certa do item
  def add_quantity browser, quantity
    (quantity -1).times do
      browser.dl(id: "j-product-quantity-info").i(class: "p-quantity-increase").click
    end
    sleep 10
  end

  #Selecionar opções do produto na Aliexpress usando array de opções da planilha
  def set_options browser, user_option
    count = 0
    browser.div(id: "j-product-info-sku").dls.each do |option|
      selected = user_option[count]
      if selected.nil?
        option.a.click
      else
        option.as[selected].click
      end
      count +=1
      sleep 10
    end
  end

  #finaliza pedido com informações do cliente
  def complete_order browser, customer
    browser.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
    browser.div(class: "bottom-info-right-wrapper").button.click #Botão Comprar
    browser.ul(class: "sa-address-list").a.click #Botão Editar Endereço
    #Preenche campos de endereço
    p 'Preenchendo informações'
    browser.text_field(name: "contactPerson").set customer["first_name"]+" "+customer["last_name"]
    browser.select_list(name: "country").select 'Brazil'
    browser.text_field(name: "address").set to_english(customer["address_1"])
    browser.text_field(name: "address2").set to_english(customer["address_2"])
    browser.text_field(name: "city").set to_english(customer["city"])
    arr = self.state.assoc(customer["state"])
    browser.div(class: "sa-province-group").select_list.select arr[1]
    browser.checkbox.clear
    browser.text_field(name: "zip").set customer["postcode"]
    browser.text_field(name: "mobileNo").set '5511959642036'
    browser.div(class: "sa-form").links[1].click #Botão Salvar
    p 'Salvando'
    sleep 5
    browser.button(id:"place-order-btn").click #Botão Finalizar pedido
    sleep 5
    browser.spans(class:"order-no") #Retorna os números dos pedidos
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
  def empty_cart browser
    p 'Esvaziando carrinho'
    browser.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
    empty = browser.link(class: "remove-all-product")
    empty.click if empty.present?
    ok = browser.div(class: "ui-window-btn").input
    ok.click if ok.present?
    sleep 5
  rescue
    @error = "Falha ao esvaziar carrinho, verificar conexão. Abortando para evitar falhas"
    # exit
  end
end
