require 'faraday'

module Orders
  class SendTrackedService

    def initialize(order)
      @order = order
    end

    def send
      post_api_request 'https://aliexpress-shipped-orders.herokuapp.com/orders', order_payload(@order)
    end

    private

    def order_payload(order)
      {
          order: {
              aliexpress_number: order.aliexpress_number,
              wordpress_reference: order.wordpress_reference,
              tracking_number: order.tracking_number
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

  end
end