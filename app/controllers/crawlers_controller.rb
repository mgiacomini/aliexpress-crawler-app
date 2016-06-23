class CrawlersController < ApplicationController
  before_action :set_crawler, only: [:edit, :update, :show, :destroy]
  def index
    @crawlers = Crawler.all
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

  private

  def set_crawler
    @crawler = Crawler.find(params[:id])
  end

  def crawler_params
    params.require(:crawler).permit(:aliexpress_id, :wordpress_id, :schedule,
                                    :enabled)
  end
end
