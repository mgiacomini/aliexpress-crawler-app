class OrdersController < ApplicationController
  skip_action :authenticate_user!, only: :track
  def index
    @orders = Order.tracked.order(:created_at)
  end

  def new
    @order = Order.new
  end

  def create
    order_creation_service = Orders::CreationService.new(Order.new(order_params))
    @order = order_creation_service.create

    if @order.instance_of? Order
      redirect_to order_path(@order)
    else
      redirect_to orders_path, notice: 'Seu pedido está sendo rastreado e pode levar alguns minutos.'
    end
  end

  def track
    order = Order.find_by(aliexpress_number: order_params[:aliexpress_number], wordpress_reference: order_params[:wordpress_reference])
    order.mark_as_tracked order_params[:tracking_number]
    head :ok
  end

  def show
    @order = Order.find(params[:id])
    respond_with @order
  end

  private

  def order_params
    params.require(:order).permit(:crawler_id, :aliexpress_number, :wordpress_reference, :tracking_number)
  end
end