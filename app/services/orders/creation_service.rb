require 'faraday'

module Orders
  class CreationService

    def initialize(order)
      @order = order
    end

    ## create method will find existing order or request to aliexpress-tracker app
    def create
      Order.find_by_aliexpress_number!(@order.aliexpress_number)
    rescue ActiveRecord::RecordNotFound
      post_api_request 'http://aliexpress-tracker.herokuapp.com/orders/track', order_payload(@order) if @order.save
    end

    private

    def order_payload(order)
      {
          order: {
              aliexpress_number: order.aliexpress_number,
              wordpress_reference: order.wordpress_reference,
              success_url: success_url,
              aliexpress: {
                  email: order.crawler.aliexpress.email, password: order.crawler.aliexpress.password
              },
              wordpress: {
                  url: order.crawler.wordpress.url,
                  consumer_key: order.crawler.wordpress.consumer_key,
                  consumer_secret: order.crawler.wordpress.consumer_secret
              }
          }
      }
    end

    def post_api_request(url, payload={})
      conn = Faraday.new(url: url)
      conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload.to_json
      end
    end

    def success_url
      return "http://localhost:3000/orders/track" if Rails.env.development?
      "http://#{ENV['HEROKU_APP_NAME']}.herokuapp.com/orders/track"
    end

  end
end