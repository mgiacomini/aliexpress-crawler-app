module Orders
  class CreationService

    def initialize(order)
      @order = order
    end

    def build_order
      Order.find_by_aliexpress_number(@order.aliexpress_number)
    rescue ActiveRecord::RecordNotFound
      browser = Watir::Browser.new :phantomjs
      Watir.default_timeout = 90
      browser.window.maximize
      tracking_service = Crawlers::OrderTrackService.new(@order, browser, OrderLog.new)
      tracking_service.track!
      @order
    end

  end
end