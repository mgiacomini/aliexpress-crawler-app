class BuyOrderWorker
  include Sidekiq::Worker

  def perform(crawler_id, crawler_log_id, order_id)
    crawler = Crawler.find crawler_id
    crawler_log = CrawlerLog.find crawler_log_id
    order = Order.find order_id
    if order.enqueued?
      crawler.run order.metadata, crawler_log
      order.processed!
    end
  end
end