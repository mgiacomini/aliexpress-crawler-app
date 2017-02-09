class OrdersController < ApplicationController
  def index
    @orders = Order.tracked.order(:created_at)
  end

  def new
    @order = Order.new
  end

  def create
    order_creation_service = Orders::CreationService.new(Order.new(order_params))
    @order = order_creation_service.build_order
    respond_with @order
  end

  def show
    @order = Order.find(params[:id])
    respond_with @order
  end

  private

  def order_params
    params.require(:order).permit(:crawler_id, :aliexpress_number, :wordpress_reference)
  end
end
