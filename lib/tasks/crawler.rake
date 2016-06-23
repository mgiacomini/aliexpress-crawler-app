namespace :crawler do
  desc "Runs Crawler.rb"
  task run: :environment do
    crawlers = Crawler.all(status: true)
    orders = crawler.wordpress.get_orders
    orders.each do |order|
      # crawler.run(orders[1])
      crawler.run(order)
    end
  end
end
