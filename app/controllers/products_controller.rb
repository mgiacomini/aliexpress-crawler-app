class ProductsController < ApplicationController
  before_action :set_product, only: [:edit, :update, :show, :destroy]
 # before_action :authenticate_user!, except: [:show]
  def index
    @products = Product.all
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
    redirect_to products_path, notice: "Product Deleted"
  end

  def import
    products = Wordpress.last.get_products
    Product.import(products)
    redirect_to products_path, notice: "Products imported."
  rescue
    redirect_to products_path, notice: "Couldn't import, check configurations."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :link, :aliexpress_link, :option_1,
                                    :option_2, :option_3, :shipping, :wordpress_id)
  end
end
