class Crawler < ActiveRecord::Base
  belongs_to :aliexpress
  belongs_to :wordpress
  validates :aliexpress_id, :wordpress_id, presence: true
  has_many :crawler_logs, dependent: :destroy
  has_many :orders, dependent: :destroy

  def run(order, log)
    raise ArgumentError, "Pedido inválido!" if order.nil?

    @log = log
    @b = Watir::Browser.new :phantomjs
    Watir.default_timeout = 90
    @b.window.maximize

    # Login and change location to Brazil
    self.login
    self.set_destination_to_brazil

    #orders.reverse_each do |order|
    @error = nil
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
      order['line_items'].each do |item|
        # Check if product type was found on database
        product_type = self.find_product_type_by_item(item)
        # If found, go to aliexpress link and check for quantities and availability
        self.check_and_go_to_aliexpress_link(product_type, item)
        # First check if shipping is set for Product
        shipping = self.get_product_shipping(product_type, item)
        # When order is completed the errors for these items are removed
        order_items << {product_type: product_type, shipping: shipping}
        # Set the options (color, size...) for the product
        self.set_item_options([product_type.option_1, product_type.option_2, product_type.option_3])
        # Set Shipping
        self.set_item_shipping(shipping)
        # Set correct quantity
        self.set_item_quantity(item['quantity'])
        # Verify if the product is not over the maximum value
        self.check_max_value(product_type, item['quantity'])
        # Finally add the current product to cart
        self.add_item_to_cart
      end

      # Finish Order if no errors found
      if @error.present?
        raise @error
      else
        # ali_order_num is the aliexpress order number returned
        customer = wordpress.get_order order['id']
        ali_order_num = self.complete_order(customer['shipping'])
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
      @b.screenshot.save("screenshots/#{e}-#{rand(1000)}.png") if Rails.env.development?
      @log.add_message(e.message)
    end
    #end
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
    sleep 5
    if !@b.a(class: "sa-edit").exists?
      if !@b.a(class: "sa-add-a-new-address").exists?
        message = 'Não foi possível inserir as informaçoes do cliente'
        @log.add_message message
        raise message
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

    # wait up to 30 (6*5) seconds for ui-add-shopcart-dialog to show up
    6.times do
      unless @b.div(class: "ui-add-shopcart-dialog").exists?
        sleep(5)
      end
    end

    unless @b.div(class: "ui-add-shopcart-dialog").exists?
      @error = "Falha ao adicionar ao carrinho"
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
      selected = (user_options[index] - 1) || 0

      if option.as[selected].exists?
        link = option.as[selected]

        # Check if the option is not disabled
        if link.parent.class_name.include?('disabled')
          raise 'Variação do produto indisponível'
        else
          link.click
          unless link.parent.class_name.include?('active')
            other_link = selected.zero? ? option.as[1] : option.as[0]
            other_link.click
            sleep(1)
            link.click
            sleep(1)
            unless link.parent.class_name.include?('active')
              raise 'Não foi possível selecionar a variação'
            end
          end
        end
      else
        raise 'Variação do produto indisponível'
      end
    end
  end

  def set_item_shipping(shipping)
    puts "========= Setting shipping"
    unless shipping == 'default'
      @b.a(class: 'shipping-link').click
      # Wait for the popup to open
      @b.div(class: 'ui-window-btn').wait_until_present(timeout: 30)
      radio = @b.radio(name: 'shipping-company', data_full_name: "#{shipping}")
      if radio.exists?
        radio.click
        # Wait for the change to propagate
        sleep 2
        @b.div(class: 'ui-window-btn').button(data_role: 'yes').click
      else
        raise 'Frete inválido'
      end
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

  def check_max_value product_type, quantity
    puts "========= Checking value"
    unless product_type.max_value
      message = 'Valor máximo não cadastrado'
      errors = product_type.product_type_errors
      error = errors.find_or_initialize_by(message: message, solved: false)
      error.occurrences += 1
      error.save
      raise message
    end

    @b.span(id: 'j-total-price-value').wait_until_present
    value = @b.span(id: 'j-total-price-value').text
    value = value.slice(4..-1).to_d
    value_per_item = value / quantity

    if value_per_item > product_type.max_value
      message = 'Valor acima do esperado'
      errors = product_type.product_type_errors
      error = errors.find_or_initialize_by(message: message, solved: false)
      error.occurrences += 1
      error.save
      raise message
    end
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

    fullname = to_english(customer["first_name"]+" "+customer["last_name"])

    # Fill customer's address
    puts "========= Adding customer informations"
    @log.add_message('Adicionando informações do cliente')
    @b.text_field(name: "contactPerson").wait_until_present(timeout: 3)
    @log.add_message(fullname)
    @b.text_field(name: "contactPerson").set fullname
    @b.select_list(name: "country").select "Brazil"
    if customer['number'].nil?
      adds = customer["address_1"]
    else
      adds = customer["address_1"]+" "+customer['number']
    end
    @log.add_message(to_english(adds))
    @b.text_field(name: "address").set to_english(adds)
    @log.add_message(to_english(customer["address_2"]))
    @b.text_field(name: "address2").set to_english(customer["address_2"])
    # Wait for States to turn on select
    sleep 1
    state = self.state.assoc(customer["state"])
    @b.div(class: "sa-province-wrapper").select_list.select state[1]
    @b.text_field(name: "city").set to_english(customer["city"])
    @b.text_field(name: "zip").set customer["postcode"]
    @b.text_field(name: "phoneCountry").set '55'
    @b.text_field(name: "mobileNo").set '941873849'
    @b.text_field(name: "cpf").set '35825265856'
    @b.a(class: "sa-confirm").click

    check_costumer_data @b, fullname

    # Placing order on desktop website
    @b.button(id: "place-order-btn").click

    puts "========= Finishing Order"
    @log.add_message('Finalizando Pedido')
    sleep 3
    if @b.span(class: "order-no").exists?
      # Return the number of the Order if there is no captcha
      @finished = true
      @b.span(class: "order-no").text
    else
      puts "========= Captcha detected, going to mobile..."
      @log.add_message('Captcha detectado, indo para carrinho mobile')
      @b.goto 'm.aliexpress.com/shopcart/detail.htm'
      @b.div(class: "buyall").wait_until_present(timeout: 30)
      @b.div(class: "buyall").click
      # Create the final order on mobile website to avoid captcha
      @b.button(id: "create-order").wait_until_present(timeout: 30)
      @b.button(id: "create-order").click
      @finished = true
      @b.div(class: "desc_txt").wait_until_present(timeout: 30)
      @b.div(class: "desc_txt").text
    end
  end

  # Convert state to Brazilian format
  def state
    [
        ["AC", "Acre"],
        ["AL", "Alagoas"],
        ["AP", "Amapa"],
        ["AM", "Amazonas"],
        ["BA", "Bahia"],
        ["CE", "Ceara"],
        ["DF", "Distrito Federal"],
        ["ES", "Espirito Santo"],
        ["GO", "Goias"],
        ["MA", "Maranhao"],
        ["MT", "Mato Grosso"],
        ["MS", "Mato Grosso do Sul"],
        ["MG", "Minas Gerais"],
        ["PA", "Para"],
        ["PB", "Paraiba"],
        ["PR", "Parana"],
        ["PE", "Pernambuco"],
        ["PI", "Piaui"],
        ["RJ", "Rio de Janeiro"],
        ["RN", "Rio Grande do Norte"],
        ["RS", "Rio Grande do Sul"],
        ["RO", "Rondonia"],
        ["RR", "Roraima"],
        ["SC", "Santa Catarina"],
        ["SP", "Sao Paulo"],
        ["SE", "Sergipe"],
        ["TO", "Tocantins"],
    ]
  end

  # if costumer data is right, nothing happens
  # otherwise, raise a RuntimeError
  def check_costumer_data(browser, fullname)
    browser.p(class: "ui-notice-normal").wait_until_present(timeout: 5)
    if browser.div(class: 'sa-username').text != fullname
      raise
    end
  rescue
    raise 'Não foi possível atualizar os dados do cliente'
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

  ## Build complex variations name
  # Example, *order_metadata* come from an array like:
  #
  # [
  #   {"key"=>"opcoes", "label"=>"opções", "value"=>"1"},
  #   {"key"=>"modelos", "label"=>"Modelos", "value"=>"iPhone 7"}
  # ]
  # and return a string "1 iphone 7"
  def build_variation_name(order_metadata = [])
    p "--> Criando nome da variação"
    @log.add_message "Criando nome da variação"
    mapped_name = order_metadata.map { |m| m['value'].gsub('-', ' ').downcase }
    mapped_name.join(' ')
  end

  def find_product_type_by_item(item)
    @log.add_message "Procurando produto: #{item['name']}"
    product = wordpress.products.find_by(id_at_wordpress: item["product_id"])
    product ||= wordpress.products.find_by(name: item['name'])

    if product
      @log.add_message "Produto ##{product.id} selecionado"
    else
      raise "Produto não encontrado. Necessário importar do wordpress."
    end

    name = 'unico' # default variation name
    name = build_variation_name(item['meta']) if item['meta'] && item['meta'].any?
    product_types = product.product_types
    product_type = product_types.where('lower(name) = ?', name).try(:first)

    if product_type
      @log.add_message "Variação ##{product_type.id} selecionada"
    else
      raise "Variação não encontrada. Necessário importar do wordpress"
    end

    product_type
  end

  def check_and_go_to_aliexpress_link(product_type, item)
    if product_type.aliexpress_link.nil?
      raise "Link aliexpress não cadastrado para: #{item['name']}"
    elsif product_type.parsed_link == "http://pt.aliexpress.com/item//"
      raise "Link aliexpress cadastrado de forma errada para: #{item['name']}"
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
      update_aliexpress_number order, ali_order_num
      message = "Pedido #{order["id"]} processado com sucesso! Pedido aliexpress: #{ali_order_num}"
      puts message
      @log.add_processed(message)
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

  def update_aliexpress_number(order, ali_order_num)
    if Rails.env.development?
      puts '========= Módo de desenvolvimento - Wordpress não será atualizado'
    else
      self.wordpress.update_order(order, ali_order_num)
    end

    o = orders.find_by(wordpress_reference: order['id'])
    o.update_attributes(aliexpress_number: ali_order_num)
    o.processed!
  end

end
