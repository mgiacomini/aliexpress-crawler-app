class ProductsController < ApplicationController
  before_action :set_product, only: [:edit, :update, :show, :destroy]
  def index
    @products = Product.all.order(:name)
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
    redirect_to products_path, alert: "Produto deletado."
  end

  def import
    products = Wordpress.last.get_products
    Product.import(products)
    redirect_to products_path, notice: "Produtos importados."
  rescue
    redirect_to products_path, alert: "Falha ao importar, checar configurações do Wordpress."
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
