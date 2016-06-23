class WordpressesController < ApplicationController
  before_action :set_wordpress, only: [:edit, :update, :show, :destroy]
  def new
    @wordpress = Wordpress.new
  end

  def create
    @wordpress = Wordpress.create(wordpress_params)
    respond_with @wordpress
  end

  def edit
    respond_with @wordpress
  end

  def update
    @wordpress.update(wordpress_params)
    respond_with @wordpress
  end

  def show
    respond_with @wordpress
  end

  def index
    @wordpresses = Wordpress.all.order(:name)
  end

  def destroy
    @wordpress.destroy
    redirect_to wordpresses_path, notice: "Wordpress configuration deleted"
  end

  private

  def set_wordpress
    @wordpress = Wordpress.find(params[:id])
  end

  def wordpress_params
    params.require(:wordpress).permit(:name, :url, :consumer_key, :consumer_secret)
  end
end
