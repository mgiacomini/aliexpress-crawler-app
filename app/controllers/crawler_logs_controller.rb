class CrawlerLogsController < ApplicationController
  before_action :set_crawler_log, only: [:show, :destroy]
  def index
    @crawler_logs = CrawlerLog.all.order(:created_at)
  end

  def show
    respond_with @wordpress
  end

  def destroy
    @crawler_log.destroy
    redirect_to crawler_loges_path, alert: "Log deletado"
  end

  private

  def set_crawler_log
    @crawler_log = Crawler_log.find(params[:id])
  end
end
