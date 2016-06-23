namespace :crawler do
  desc "Runs Crawler.rb"
  task run: :environment do
    crawler = Crawler.last
    orders = crawler.wordpress.get_orders
    orders.each do |order|
      crawler.run(order)
    end
  end
end
