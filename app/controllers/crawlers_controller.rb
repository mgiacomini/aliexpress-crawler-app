class CrawlersController < ApplicationController
  before_action :set_crawler, only: [:edit, :update, :show, :destroy, :run]
  def index
    @crawlers = Crawler.all.order(:created_at)
  end
  def new
    @crawler = Crawler.new
  end

  def create
    @crawler = Crawler.create(crawler_params)
    respond_with @crawler
  end

  def edit
    respond_with @crawler
  end

  def update
    @crawler.update(crawler_params)
    respond_with @crawler
  end

  def show
    respond_with @crawler
  end

  def destroy
    @crawler.destroy
    redirect_to crawlers_path, notice: "Crawler Deleted"
  end

  def run
    orders = @crawler.wordpress.get_orders
    orders.each do |order|
      @crawler.run(order)
    end
    redirect_to crawlers_path, notice: "#{orders.count} pedidos processados"
  end

  private

  def set_crawler
    @crawler = Crawler.find(params[:id])
  end

  def crawler_params
    params.require(:crawler).permit(:aliexpress_id, :wordpress_id, :schedule,
                                    :enabled)
  end
end
