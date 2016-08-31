class CrawlersController < ApplicationController
  before_action :set_crawler, only: [:edit, :update, :show, :destroy, :enabled_status]
  def index
    @crawlers = Crawler.all.order(:created_at
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
    @crawler_logs = @crawler.crawler_logs.order(created_at: :desc)
    respond_with @crawler
  end

  def destroy
    @crawler.destroy
    redirect_to crawlers_path, alert: "Crawler Deleted"
  end

  def enabled_status
    case params[:type]
    when 'enable'
      enable
    when 'disable'
      disable
    else
      redirect_to :back
    end
    @crawler.save
  end

  private

  def enable
    @crawler.enabled = true
    redirect_to :back, notice: "Você ativou o crawler de #{@crawler.aliexpress.name} para #{@crawler.wordpress.name}"
  end

  def disable
    @crawler.enabled = false
    redirect_to :back, alert: "Você desativou o crawler de #{@crawler.aliexpress.name} para #{@crawler.wordpress.name}"
  end

  def set_crawler
    @crawler = Crawler.find(params[:id])
  end

  def crawler_params
    params.require(:crawler).permit(:aliexpress_id, :wordpress_id, :schedule,
                                    :enabled)
  end
end
