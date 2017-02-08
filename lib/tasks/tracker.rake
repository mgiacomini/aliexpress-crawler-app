namespace :tracker do

  desc "Runs Crawler::OrderTrackService"
  task run: :environment do
    @browser = Watir::Browser.new :phantomjs
    Watir.default_timeout = 90
    @browser.window.maximize

    orders = Order.untracked
    orders.each do |order|
      tracking_service = Crawlers::OrderTrackService.new(order, @browser, OrderLog.new)
      tracking_service.track!
    end

    @browser.close
  end

end
