namespace :crawler do
  desc "Runs Crawler.rb"
  task run: :environment do
    crawler = Crawler.where(enabled: true).last
    orders = crawler.wordpress.get_orders
    orders.each do |order|
      # crawler.run(orders[1])
      crawler.run(order)
    end
  end
end
