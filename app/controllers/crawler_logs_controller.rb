class CrawlerLogsController < ApplicationController
  before_action :set_crawler_log, only: [:show, :destroy]
  def index
    @crawler_logs = CrawlerLog.all
  end

  def show
    respond_with @wordpress
  end

  def destroy
    @crawler_log.destroy
    redirect_to crawler_logs_path, alert: "Log deletado"
  end

  private

  def set_crawler_log
    @crawler_log = CrawlerLog.find(params[:id])
  end
end
