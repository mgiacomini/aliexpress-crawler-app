class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
  validates :aliexpress_id, :wordpress_id, presence: true
  has_many :crawler_logs, dependent: :destroy

  def run(orders)
    raise "Não há pedidos a serem executados" if orders.nil? || orders.count == 0

    @log = CrawlerLog.create!(crawler: self, orders_count: orders.count)
    @b = Watir::Browser.new :phantomjs
    Watir.default_timeout = 90
    @b.window.maximize

    # Login and change location to Brazil
    self.login
    self.set_destination_to_brazil

    orders.reverse_each do |order|
      @error = nil
      @order = order
      @finished = false

      tries ||= 3
      order_items = []
      # Start processing Order
      message = "\n------------------- Processando pedido ##{order['id']}\n"
      puts message
      @log.add_message(message)
      # Check if this Order is already processed
      self.check_order_notes(order)
      # Start putting items inside the cart and setting options
      begin
        # Empty the Cart before go to next Order
        # empty_cart is inside begin so this way we can rescue the
        # Net::ReadTimeout problems
        self.empty_cart
        order["line_items"].each do |item|
          # Set product and product options from Wordpress products
          product = Product.find_by_name(item["name"])
          # Search product_types
          product_type = ProductType.find_by(product: product)
          # Check if product was found on database
          self.check_product_or_product_type(product, product_type, item)
          # If found, go to aliexpress link and check for quantities and availability
          self.check_and_go_to_aliexpress_link(product_type, item)
          # First check if shipping is set for Product
          shipping = self.get_product_shipping(product_type, item)
          # Qhen order is completed the errors for this item are removed
          order_items << { product_type: product_type, shipping: shipping }
          # Set the options (color, size...) for the product
          self.set_item_options([product_type.option_1, product_type.option_2, product_type.option_3])
          # Set Shipping
          self.set_item_shipping(shipping)
          # Set correct quantity
          self.set_item_quantity(item['quantity'])
          # Finally add the current product to cart
          self.add_item_to_cart
        end

        # Finish Order if no errors found
        if @error.present?
          raise @error
        else
          # ali_order_num is the aliexpress order number returned
          ali_order_num = self.complete_order(order["shipping_address"])
          # check if order was successful finished
          self.check_order_number(ali_order_num, order)
          # Clean current errors if this order
          ProductType.clear_errors(order_items)
        end
      rescue Net::ReadTimeout => e
        @log.add_message("Erro de timeout, Tentando mais #{tries-1} vezes")
        retry unless (tries -= 1).zero? || @finished
      rescue => e
        # when you raise and pass message, this message is printed here
        puts e.message
        @log.add_message(e.message)
      end
    end
    # Close Watir Browser when finish
    @b.close
  end

  # Efetua login no site da Aliexpresss usando user e password
  def login
    tries ||= 3
    puts "========= Performing Login"
    @log.add_message("Efetuando login com #{self.aliexpress.email}\n")
    @b.goto "https://login.aliexpress.com/"
    frame = @b.iframe(id: 'alibaba-login-box')
    frame.text_field(name: 'loginId').set self.aliexpress.email
    sleep 1
    frame.text_field(name: 'password').set self.aliexpress.password
    sleep 1
    frame.button(name: 'submit-btn').click
    sleep 5
  rescue => e
    puts e.message
    @log.add_message "Erro de login, Tentando mais #{tries} vezes"
    @log.add_message e.message
    retry unless (tries -= 1).zero?
  end

  def check_if_session_is_up
    tries ||= 3
    sleep 5
    # @b.a(class: "sa-edit").wait_until_present(timeout: 30)
    if !@b.a(class: "sa-edit").exists?
      if !@b.a(class: "sa-add-a-new-address").exists?
        message = "Sessão desconectada ... logando novamente"
        puts message
        @log.add_message message
        self.login
      else
        @b.a(class: "sa-add-a-new-address").click
      end
    else
      @b.a(class: "sa-edit").click
    end
  end

  def set_destination_to_brazil
    puts "========= Setting destination to Brazil"
    @b.span(class: 'ship-to').wait_until_present(timeout: 30)
    @b.span(class: 'ship-to').click
    sleep 5
    @b.div(data_role: 'switch-country').wait_until_present(timeout: 30)
    @b.div(data_role: 'switch-country').click

    @b.span(class: 'css_br').wait_until_present(timeout: 30)
    @b.span(class: 'css_br').click

    @b.div(class: 'switcher-btn').button(data_role: 'save').wait_until_present(timeout: 30)
    @b.div(class: 'switcher-btn').button(data_role: 'save').click
    sleep 5
  end

  # Add current item to the Cart
  def add_item_to_cart
    puts "========= Adding to cart"
    @b.link(id: "j-add-cart-btn").click
    @b.div(class: "ui-add-shopcart-dialog").wait_until_present(timeout: 30)
    unless @b.div(class: "ui-add-shopcart-dialog").exists?
      @error = "Falha ao adicionar ao carrinho: #{@b.url}"
      @log.add_message(@error)
    end
  end

  # Change item quantity
  def set_item_quantity quantity
    puts "========= Changing quantities"
    (quantity-1).times do
      @b.dl(id: "j-product-quantity-info").i(class: "p-quantity-increase").click
    end
  end

  # Select item color, size, and other pre-configured choices
  def set_item_options user_options
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

  def set_item_shipping(shipping)
    puts "========= Setting shipping"
    unless shipping == 'default'
      @b.a(class: 'shipping-link').click
      # Wait for the popup to open
      @b.div(class: 'ui-window-btn').wait_until_present(timeout: 30)
      @b.radio(name: 'shipping-company', data_full_name: "#{shipping}").click
      # Wait for the change to propagate
      sleep 2
      @b.div(class: 'ui-window-btn').button(data_role: 'yes').click
    end
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
    # Go to Cart Page
    @b.goto 'https://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'
    # Check if all items can be purchased
    sleep 5
    if @b.button(class: "buy-now-disabled-info").exists?
      raise "Um dos produtos do carrinho não está mais disponível"
    end
    @b.button(class: "buy-now").wait_until_present(timeout: 30)
    if !@b.button(class: "buy-now").exists?
      raise "Produto sem estoque na Aliexpress"
    else
      @b.button(class: "buy-now").click
    end
    # Check if current session if up
    self.check_if_session_is_up
    # Fill customer's address
    puts "========= Adding customer informations"
    @log.add_message('Adicionando informações do cliente')
    @b.text_field(name: "contactPerson").wait_until_present(timeout: 3)
    @b.text_field(name: "contactPerson").set to_english(customer["first_name"]+" "+customer["last_name"])
    @b.select_list(name: "country").select "Brazil"
    if customer['number'].nil?
      @b.text_field(name: "address").set to_english(customer["address_1"])
    else
      @b.text_field(name: "address").set to_english(customer["address_1"]+" "+customer['number'])
    end
    @b.text_field(name: "address2").set to_english(customer["address_2"])
    # Wait for States to turn on select
    sleep 1
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

    # Placing order on desktop website
    @b.button(id: "place-order-btn").click

    puts "========= Finishing Order"
    @log.add_message('Finalizando Pedido')
    sleep 3
    if @b.span(class:"order-no").exists?
      # Return the number of the Order if there is no captcha
      @finished = true
      @b.span(class:"order-no").text
    else
      puts "========= Captcha detected, going to mobile..."
      @log.add_message('Captcha detectado, indo para carrinho mobile')
      @b.goto 'm.aliexpress.com/shopcart/detail.htm'
      @b.div(class:"buyall").wait_until_present(timeout: 30)
      @b.div(class:"buyall").click
      # Create the final order on mobile website to avoid captcha
      @b.button(id:"create-order").wait_until_present(timeout: 30)
      @b.button(id:"create-order").click
      @finished = true
      @b.div(class:"desc_txt").wait_until_present(timeout: 30)
      @b.div(class:"desc_txt").text
    end
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
    @b.goto 'http://shoppingcart.aliexpress.com/shopcart/shopcartDetail.htm'

    if @b.link(class: "remove-all-product").exists?
      @b.link(class: "remove-all-product").click
      @b.div(class: "ui-window-btn").button.click
    end
  end

  def check_product_or_product_type(product, product_type, item)
    if product.nil? && product_type.nil?
      raise "Produto #{item["name"]} não encontrado, necessário importar do wordpress"
    end
  end

  def check_and_go_to_aliexpress_link(product_type, item)
    if product_type.aliexpress_link.nil?
      raise "Link aliexpress não cadastrado para: #{item['name']}"
    elsif product_type.parsed_link == "http://pt.aliexpress.com/item//"
      raise "Link aliexpress cadastrdo de forma errada para: #{item['name']}"
    else
      # Go to Product's page
      message = "Going to aliexpress --> #{product_type.parsed_link}"
      puts message
      @log.add_message message
      @b.goto product_type.parsed_link
      # Verify if item is available
      sleep 5
      if !@b.em(id: 'j-sell-stock-num').exists? || @b.em(id: 'j-sell-stock-num').text.to_i < item['quantity']
        raise "Erro de estoque, produto #{item["name"]} não disponível"
      end
    end
  end

  def check_current_cart_items(line_items)
    @b.goto 'https://m.aliexpress.com/shopcart/detail.htm'

    if @b.lis(id: "shopcart-").count != line_items.count
      raise "Erro com itens do carrinho, cancelando pedido"
    end
  end

  def check_order_number(ali_order_num, order)
    if ali_order_num.blank?
      raise "Erro com numero do pedido vazio\n"+self.wordpress.error
    else
      self.wordpress.update_order(order, ali_order_num)
      puts "Pedido #{order["id"]} processado com sucesso! Pedido aliexpress: #{ali_order_num}"
      @log.add_processed("Pedido #{order["id"]} processado com sucesso! Pedido aliexpress: #{ali_order_num}")
    end
  end

  def check_order_notes(order)
    notes = self.wordpress.get_notes(order)
    unless notes.empty?
      notes.each do |note|
        if note["note"].include? "Concluído"
          self.wordpress.complete_order(order)
          @log.add_message "Pedido ja executado!"
          next
        end
      end
    end
  end

  def get_product_shipping(product_type, item)
    if product_type.shipping.present?
      product_type.shipping
    else
      @log.add_message("Frete, não especificado para #{item['name']}, usando o padrão")
      # return default choice
      'default'
    end
  end
end
