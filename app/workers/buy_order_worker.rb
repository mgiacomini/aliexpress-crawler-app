class BuyOrderWorker
  include Sidekiq::Worker

  def perform(crawler_id, crawler_log_id, order={})
    crawler = Crawler.find crawler_id
    crawler_log = CrawlerLog.find crawler_log_id
    crawler.run order, crawler_log
  end
end
