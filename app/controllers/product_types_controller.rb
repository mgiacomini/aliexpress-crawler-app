class ProductTypesController < ApplicationController
  before_action :set_product_type, only: [:edit, :update, :show, :destroy]
  def index
    @productTypes = ProductType.all

  def edit
    respond_with @product_type
  end

  def update
    @product_type.update(product_type_params)
    respond_with @product_type
  end

  def show
    respond_with @product_type
  end

  def destroy
    @product_type.destroy
    redirect_to product_types_path, alert: "Tipo de produto deletado."
  end

  def import_all
    Wordpress.all.each do |wordpress|
      @products = wordpress.get_products
      Product.import(@products, wordpress)
    end
    redirect_to product_types_path, notice: "Produtos importados."
  rescue
    redirect_to product_types_path, alert: "Falha ao importar, checar configurações do Wordpress."
  end

  private

  def set_product_type
    @product_type = ProductType.find(params[:id])
  end

  def product_type_params
    params.require(:product_type).permit(:name, :aliexpress_link, :option_1,
                                    :option_2, :option_3, :shipping)
  end
end
