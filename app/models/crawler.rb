require "watir-webdriver"
class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
  validates :aliexpress_id, :wordpress_id, presence: true
  has_many :crawler_logs

  def run(orders)
    raise "Não há pedidos a serem executados" if orders.nil? || orders.count == 0

    @log = CrawlerLog.create!(crawler: self, orders_count: orders.count)
    @b = Watir::Browser.new :phantomjs
    Watir.default_timeout = 90
    @b.window.maximize

    orders.reverse_each do |order|
      @error = nil
      @finished = false

      begin
        tries ||= 3
        message = "-------------------\nProcessando pedido ##{order['id']}"
        # Empty the Cart before go to next Order
        self.empty_cart
        puts message
        @log.add_message(message)

        notes = self.wordpress.get_notes order
        unless notes.empty?
          notes.each do |note|
            if note["note"].include? "Concluído"
              self.wordpress.complete_order(order)
              raise "Pedido ja executado!"
            end
          end
        end

        order_items = []
        order["line_items"].each do |item|
          # Set product and product options from Wordpress products
          product = Product.find_by_name(item["name"])
          # Search product_types
          product_type = ProductType.find_by(product: product)
          # Define product type (holds color, size and shipping infos)
          # if (item["meta"]).empty?
          # else
          #   name = ""
          #   item["meta"].each {|option| name.concat("#{option['value']} ")}
          #   product_type = ProductType.find_by(product: product, name: name.strip)
          # end
          # Check if product was found on database
          self.check_product_or_product_type(product, product_type, item)
          # Set correct quantities
          quantity = item["quantity"]
          # ...and shipping method
          if product_type.shipping.present?
            shipping = product_type.shipping
          else
            @log.add_message(@error)
            raise "Método de entrega não especificado para #{item['name']}"
          end

          order_items << { product_type: product_type, shipping: shipping }

          begin
            # If found, go to aliexpress link and check for quantities and availability
            self.check_and_go_to_aliexpress_link(product_type, quantity, item)
            # Set the options (color, size...) for the product
            self.set_options([product_type.option_1, product_type.option_2, product_type.option_3])
            # Set Shipping
            self.set_shipping(shipping)
            # Set correct quantity
            self.add_quantity(quantity)
            # Finally add the current product to cart
            self.add_to_cart
          rescue => e
            @error = "Ocorreu um erro com o item: #{item["name"]}\n"+e.message
            @log.add_message(@error)
            # Add errors to final hash {}
            product_type.add_error if product && product_type
            break
          end
        end

        # Finish Order if no errors found
        if @error.nil?
          # Check if all items from order are present on cart
          # self.check_current_cart_items(order['line_items'])

          # ali_order_num is the aliexpress order number returned from
          # the order processing
          ali_order_num = self.complete_order(order["shipping_address"])
          # check if order was successful finished
          if self.check_order_number(ali_order_num)
            @log.add_message("Pedido completado na Aliexpress")
            @log.add_processed("Pedido #{order["id"]} processado com sucesso! Pedido aliexpress: #{ali_order_num}")
          end
          # Clean current errors if this order
          ProductType.clear_errors(order_items)
        elsif @error.present?
          raise @error
        else
          raise
        end
      rescue Net::ReadTimeout => e
        @log.add_message("Erro de timeout, Tentando mais #{tries-1} vezes")
        retry unless (tries -= 1).zero? || @finished
      rescue => e
        @error = "Erro ao concluir pedido #{order["id"]}, verificar aliexpress e wordpress.\n"+e.message
        @log.add_message(@error)
      end
    end

    @b.close

  rescue => e
    @log.add_message("Erro desconhecido, procurar administrador.\n"+e.message)
  end


  # Efetua login no site da Aliexpresss usando user e password
  def login
    puts "========= Performing Login"
    tries ||= 3
    @log.add_message("Efetuando login com #{self.aliexpress.email}\n")
    @b.goto "https://login.aliexpress.com/"
    frame = @b.iframe(id: 'alibaba-login-box')
    frame.text_field(name: 'loginId').set self.aliexpress.email
    frame.text_field(name: 'password').set self.aliexpress.password
    sleep 1
    frame.button(name: 'submit-btn').click
    sleep 5
  rescue
    @log.add_message("Erro de login, Tentando mais #{tries} vezes")
    retry unless (tries -= 1).zero?
  end

  # Add current item to the Cart
  def add_to_cart
    puts "========= Adding to cart"
    @b.link(id: "j-add-cart-btn").click
    sleep 2
    unless @b.div(class: "ui-add-shopcart-dialog").exists?
      @error = "Falha ao adicionar ao carrinho: #{@b.url}"
      @log.add_message(@error)
    end
  end

  # Change item quantity
  def add_quantity quantity
    puts "========= Changing quantities"
    (quantity-1).times do
      @b.dl(id: "j-product-quantity-info").i(class: "p-quantity-increase").click
    end
    sleep 1
  end

  # Select item color, size, and other pre-configured choices
  def set_options user_options
    puts "========= Setting product options"
    @b.div(id: "j-product-info-sku").dls.each_with_index do |option, index|
      selected = user_options[index]
      if selected.nil?
        option.a.click
      else
        option.as[selected-1].click
      end
    end
  end

  def set_shipping(shipping = 'China Post Registered Air Mail')
    puts "========= Setting shipping"
    @b.a(class: 'shipping-link').click
    # Wait for the popup to open
    sleep 1
    @b.radio(name: 'shipping-company', data_full_name: "#{shipping}").click
    # Wait for the change to propagate
    sleep 1
    @b.div(class: 'ui-window-btn').button(data_role: 'yes').click
  end

  def add_to_cart_mobile
    puts "========= Adding to cart (mobile)"
    if @b.a(class: "back").present?
      @b.a(class: "back").click
      @b.button.click
    else
      @b.buttons[2].click
    end
    sleep 1
  end

  # Complete order with Customer informations
  def complete_order customer
    puts "========= Completing Order"
    self.login
    # Go to Cart Page
    @b.goto 'https://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
    # Go to Checkout page
    @b.button(class: "buy-now").click
    @b.a(class: "sa-edit").exists? ? @b.a(class: "sa-edit").click : @b.a(class: "sa-add-a-new-address").click
    @log.add_message('Adicionando informações do cliente')
    @b.text_field(name: "contactPerson").set to_english(customer["first_name"]+" "+customer["last_name"])
    @b.select_list(name: "country").select "Brazil"
    if customer['number'].nil?
      @b.text_field(name: "address").set to_english(customer["address_1"])
    else
      @b.text_field(name: "address").set to_english(customer["address_1"]+" "+customer['number'])
    end
    @b.text_field(name: "address2").set to_english(customer["address_2"])
    state = self.state.assoc(customer["state"])
    @b.div(class: "sa-province-wrapper").select_list.select state[1]
    @b.text_field(name: "city").set to_english(customer["city"])
    @b.text_field(name: "zip").set customer["postcode"]
    @b.text_field(name: "phoneCountry").set '55'
    @b.text_field(name: "phoneArea").set '55'
    @b.text_field(name: "phoneNumber").set '11'
    @b.text_field(name: "mobileNo").set '941873849'
    @b.text_field(name: "cpf").set '35825265856'
    @b.a(class: "sa-confirm").click
    sleep 2
    @b.button(id: "place-order-btn").click
    @log.add_message('Finalizando Pedido')
    @finished = true
    # Return the number of the Order
    @b.span(class:"order-no").text
  end

  # Convert state to Brazilian format
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

  # Remove special characters
  def to_english string
    string.tr("ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž", "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz")
          .tr("^A-Za-z0-9 ", '')
  end

  # Empty cart after finish an order
  def empty_cart
    puts "========= Emptying Cart"
    tries ||= 3
    @b.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'

    empty = @b.link(class: "remove-all-product")

    if empty.exists?
      empty.click
      @b.div(class: "ui-window-btn").button.click
    end

  rescue => e
    @log.add_message("Falha ao esvaziar carrinho, verificar conexão, tentando mais #{tries} vez(es)\n"+e.message)
    retry unless (tries -= 1).zero?
    exit
  end

  def check_product_or_product_type(product, product_type, item)
    if product.nil? && product_type.nil?
      message = "Produto #{item["name"]} não encontrado, necessário importar do wordpress"
      @log.add_message(message)
      raise message
    end
  end

  def check_and_go_to_aliexpress_link(product_type, quantity, item)
    if product_type.aliexpress_link.nil?
      message = "Link aliexpress não cadastrado para #{item['name']}"
      @log.add_message(message)
      raise message
    else
      # Go to Product's page
      @b.goto product_type.parsed_link
      # Verify if item is available
      if !@b.text_field(name: 'quantity').exists? || @b.text_field(name: 'quantity').value.to_i != quantity
        message =  "Erro de estoque, produto #{item["name"]} não disponível"
        @log.add_message(message)
        raise message
      end
    end
  end

  def check_current_cart_items(line_items)
    @b.goto 'https://m.aliexpress.com/shopcart/detail.htm'

    if @b.lis(id: "shopcart-").count != line_items.count
      message = "Erro com itens do carrinho, cancelando pedido"
      @log.add_message(message)
      raise message
    end
  end

  def check_order_number(ali_order_num)
    if ali_order_num.blank?
      message = "Erro com numero do pedido vazio"
      self.wordpress.update_order(order, ali_order_num)
      @log.add_message("Erro com numero do pedido vazio\n"+self.wordpress.error)
      raise message
    end
  end
end
