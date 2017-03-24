namespace :crawler do
  desc "Runs Crawler.rb"
  task run: :environment do
    # When run straight from command line, @crawlers won't be set so
    @crawlers ||= Crawler.where(enabled: true)

    @crawlers.each do |crawler|
      amount = crawler.max_amount_of_orders
      page = crawler.orders_starting_from_page

      failed_orders = crawler.orders.failed
      new_orders = crawler.wordpress.get_orders(amount, page).reject do |order|
        crawler.orders.exists?(wordpress_reference: order['id'])
      end

      # merge failed orders with new orders
      # others existing orders will be enqueued
      orders = failed_orders + new_orders
      crawler_log = CrawlerLog.create!(crawler: crawler, orders_count: orders.count)

      orders.each do |order|
        # retry an failed order
        if order.instance_of? Order
          o = order
          o.enqueued!
        else # new order
          o = Order.new(status: :enqueued, crawler: crawler, wordpress_reference: order['id'])
        end
        BuyOrderWorker.perform_async(crawler.id, crawler_log.id, o.id) if o.save
      end
    end
  end

  desc "Runs every 10 minutes"
  task tenminutes: :environment do
    @crawlers = Crawler.where(schedule: 'ten_minutes', enabled: true)
    unless @crawlers.nil?
      Rake::Task['crawler:run'].execute
    end
  end

  desc "Runs every hour"
  task hourly: :environment do
    @crawlers = Crawler.where(schedule: 'hourly', enabled: true)
    unless @crawlers.nil?
      Rake::Task['crawler:run'].execute
    end
  end

  desc "Runs every day"
  task daily: :environment do
    @crawlers = Crawler.where(schedule: 'daily', enabled: true)
    unless @crawlers.nil?
      Rake::Task['crawler:run'].execute
    end
  end
end
