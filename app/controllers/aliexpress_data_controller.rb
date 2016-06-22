class AliexpressDataController < ApplicationController
  before_action :set_aliexpress_datum, only: [:edit, :update, :show, :destroy]
  def new
    @aliexpress_datum = AliexpressDatum.new
  end

  def create
    @aliexpress_datum = AliexpressDatum.create(aliexpress_datum_params)
    respond_with @aliexpress_datum
  end

  def edit
    respond_with @aliexpress_datum
  end

  def update
    @aliexpress_datum.update(aliexpress_datum_params)
    respond_with @aliexpress_datum
  end

  def show
    respond_with @aliexpress_datum
  end

  def index
    @aliexpress_data = AliexpressDatum.all
  end

  private

  def set_aliexpress_datum
    @aliexpress_datum = AliexpressDatum.find(params[:id])
  end

  def aliexpress_datum_params
    params.require(:aliexpress_datum).permit(:url, :consumer_key, :consumer_secret)
  end
end
