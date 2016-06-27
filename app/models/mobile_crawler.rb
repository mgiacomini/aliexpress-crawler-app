# require "watir-webdriver"
require 'mechanize'
class MobileCrawler
  # belongs_to :aliexpress
#   belongs_to :wordpress
#   validates :aliexpress_id, :wordpress_id, presence: true
#   has_many :crawler_logs
  @log = nil
  @error = nil
#
  def run(orders)
#     @log = CrawlerLog.create!(crawler: self)
#     @log.update(orders_count: orders.count)
#     raise if orders.count == 0
    @b = self.login
#     raise login_error if @b.nil?
#     orders.each do |order|
#       @error = nil
#       begin
#         self.empty_cart @b #Esvazia Carrinho
#         @log.add_message("-------------------")
#         @log.add_message("Processando pedido ##{order['id']}")
#         p @log.message
#         customer = order["shipping_address"] #Loop para todos os produtos
#         order["line_items"].each do |item|
#           begin
#             quantity = item["quantity"]
#             product = Product.find_by_name(item["name"])
#             if (meta = item["meta"]).empty?
#               product_type = ProductType.find_by_product_id(product.id)
#             else
#               product_type = ProductType.find_by(product: product, name: meta[0]['value'])
#             end
#             @b.goto product_type.aliexpress_link #Abre link do produto
#             raise if product_type.aliexpress_link.nil?
#             stock = @b.dl(id: "j-product-quantity-info").text.split[2].gsub("(","").to_i
#             if quantity > stock #Verifica estoque
#               @error =  "Erro de estoque, produto #{product['name']} não disponível!"
#               @log.add_message(@error)
#               p @log
#               break
#             else
#               #Ações dos produtos
#               p "Adicionando #{quantity} ao carrinho"
#               self.add_quantity @b, quantity
#               p 'Selecionando opções'
#               user_options = [product_type.option_1,product_type.option_3,product_type.option_3]
#               self.set_options @b, user_options
#               # self.set_shipping @b, user_options
#               p 'Adicionando ao carrinho'
#               self.add_to_cart @b
#             end
#           rescue
#             @error = "Erro no produto #{item["name"]}, verificar link do produto na aliexpress, este pedido será pulado."
#             @log.add_message(@error)
#             p @log
#             break
#           end
#         end
#         #Finaliza pedido
#         if @error.nil?
#           order_nos = self.complete_order(@b,customer)
#           p "Pedido completado"
#           raise order_error if order_nos.count == 0
#           self.wordpress.update_order(order, order_nos)
#           @error = self.wordpress.error
#           @log.add_message(@error)
#           p @log
#           @log.add_processed("Pedido #{order["id"]} processado com sucesso!")
#           p @log
#         else
#           raise order_error
#         end
#
#       rescue => order_error
#         @error = "Erro ao concluir pedido #{order["id"]}, verificar aliexpress e wordpress."
#         @log.add_message(@error)
#         p @log
#         next
#       end
#     end
#   @b.close
#   rescue
#     @error = "Não há pedidos a serem executados"
#     @log.add_message(@error)
#     p @log
#   rescue => login_error
#     @error = "Falha no login, verifique as informações ou tente novamente mais tarde"
#     @log.add_message(@error)
#     p @log
  end
#
#   #Efetua login no site da Aliexpresss usando user e password
  def login
#     @log.add_message("Efetuando login com #{self.aliexpress.email}")
#     p @log
    agent = Mechanize.new
#     user = self.aliexpress
    page = agent.get("https://login.aliexpress.com/")
    binding.pry
#     frame = @b.iframe(id: 'alibaba-login-box')
#     frame.text_field(name: 'loginId').set user.email
#     frame.text_field(name: 'password').set user.password
#     frame.button(name: 'submit-btn').click
#     sleep 5
#     @b
#   rescue
  end
#
#   #Adiciona item ao carrinho
#   def add_to_cart browser
#     browser.link(id: "j-add-cart-btn").click
#     sleep 10
#   end
#
#   #Adiciona quantidade certa do item
#   def add_quantity browser, quantity
#     (quantity -1).times do
#       browser.dl(id: "j-product-quantity-info").i(class: "p-quantity-increase").click
#     end
#   end
#
#   #Selecionar opções do produto na Aliexpress usando array de opções da planilha
#   def set_options browser, user_option
#     count = 0
#     browser.div(id: "j-product-info-sku").dls.each do |option|
#       selected = user_option[count]
#       if selected.nil?
#         option.a.click
#       else
#         option.as[selected].click
#       end
#       count +=1
#     end
#   end
#
#   #finaliza pedido com informações do cliente
#   def complete_order browser, customer
#     browser.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
#     browser.div(class: "bottom-info-right-wrapper").button.click #Botão Comprar
#     browser.ul(class: "sa-address-list").a.click #Botão Editar Endereço
#     #Preenche campos de endereço
#     @log.add_message('Adicionando informações do cliente')
#     p @log
#     browser.text_field(name: "contactPerson").set to_english(customer["first_name"]+" "+customer["last_name"])
#     browser.select_list(name: "country").select 'Brazil'
#     browser.text_field(name: "address").set to_english(customer["address_1"])
#     browser.text_field(name: "address2").set to_english(customer["address_2"])
#     browser.text_field(name: "city").set to_english(customer["city"])
#     arr = self.state.assoc(customer["state"])
#     browser.div(class: "sa-province-group").select_list.select arr[1]
#     browser.checkbox.clear
#     browser.text_field(name: "zip").set customer["postcode"]
#     browser.text_field(name: "mobileNo").set '5511959642036'
#     browser.div(class: "sa-form").links[1].click #Botão Salvar
#     p 'Salvando'
#     sleep 2
#     p 'Selecionando Pagamento'
#     payment = browser.div(class: "other-payment-item")
#     payment.radio.set if payment.present?
#     captcha = browser.div(class: "captcha-box")
#     @log.add_message("Encontrei captcha ao finalizar o pedido!") if captcha.present?
#     browser.button(id:"place-order-btn").click #Botão Finalizar pedido
#     p 'Finalizando Pedido'
#     sleep 5
#     browser.spans(class:"order-no") #Retorna os números dos pedidos
#   end
#
#   #Tabela de conversão de Estados
#   def state
#     [
#       ["AC","Acre"],
#       ["AL","Alagoas"],
#       ["AP","Amapa"],
#       ["AM","Amazonas"],
#       ["BA","Bahia"],
#       ["CE","Ceara"],
#       ["DF","Distrito Federal"],
#       ["ES","Espirito Santo"],
#       ["GO","Goias"],
#       ["MA","Maranhao"],
#       ["MT","Mato Grosso"],
#       ["MS","Mato Grosso do Sul"],
#       ["MG","Minas Gerais"],
#       ["PA","Para"],
#       ["PB","Paraiba"],
#       ["PR","Parana"],
#       ["PE","Pernambuco"],
#       ["PI","Piaui"],
#       ["RJ","Rio de Janeiro"],
#       ["RN","Rio Grande do Norte"],
#       ["RS","Rio Grande do Sul"],
#       ["RO","Rondonia"],
#       ["RR","Roraima"],
#       ["SC","Santa Catarina"],
#       ["SP","Sao Paulo"],
#       ["SE","Sergipe"],
#       ["TO","Tocantins"],
#     ]
#   end
#
#   #Retira acentos e caracteres especiais
#   def to_english string
#     string.tr("ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž", "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
#           .tr("^A-Za-z0-9 ", '')
#   end
#
#   #Esvazia carrinho
#   def empty_cart browser
#     p 'Esvaziando carrinho'
#     browser.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
#     empty = browser.link(class: "remove-all-product")
#     empty.click if empty.present?
#     ok = browser.div(class: "ui-window-btn").input
#     ok.click if ok.present?
#     sleep 5
#   rescue
#     @error = "Falha ao esvaziar carrinho, verificar conexão. Abortando para evitar falhas"
#     @log.add_message(@error)
#     p @log
#     # exit
#   end
end
