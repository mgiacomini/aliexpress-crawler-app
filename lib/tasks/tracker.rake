namespace :tracker do

  desc "Request for aliexpress-tracker app track the order"
  task run: :environment do
    orders = Order.untracked.where('created_at <= :four_days_ago',
                                   four_days_ago: Time.now - 4.days)
    orders.each do |o|
      Orders::CreationService.new(o).create
    end
  end

  desc "Notify Wordpresses clients with tracking number of tracked orders"
  task notify_wordpresses: :environment do
    orders = Order.tracked
    orders.each do |o|
      p "====== Notificando wordpress: #{o.crawler.wordpress.name}; Pedido: #{o.aliexpress_number}"
      o.notify_wordpress
    end
  end

  desc "Send tracked orders to an unique place for search"
  task send_tracked_orders: :environment do
    orders = Order.tracked
    orders.each do |o|
      p "====== Enviando para a aplicação o pedido: #{o.aliexpress_number}"
      Orders::SendTrackedService.new(o).send
    end
  end

end
