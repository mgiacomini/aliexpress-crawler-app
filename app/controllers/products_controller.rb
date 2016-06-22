class ProductsController < ApplicationController
  before_action :set_product, only: [:edit, :update, :show, :destroy]
 # before_action :authenticate_user!, except: [:show]
  def index
    @products = Product.all
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.create(product_params)
    # @product.user = current_user
    respond_with @product
  end

  def edit
    respond_with @product
  end

  def update
    @product.update(product_params)
    respond_with @product
  end

  def show
    respond_with @product
  end

  def destroy
    @product.destroy
  end

  def import
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :link, :aliexpress_link, :option_1,
                                    :option_2, :option_3, :shipping)
  end
end
