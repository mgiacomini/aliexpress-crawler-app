namespace :crawler do
  desc "Runs Crawler.rb"
  task run: :environment do
    crawler = Crawler.where(enabled: true).first
    orders = crawler.wordpress.get_orders
    # crawler.run(orders[1])
    orders.each do |order|
      crawler.run(order)
    end
  end
end
