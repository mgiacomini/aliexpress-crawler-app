class ProductsController < ApplicationController
  def import_all
    raise if Wordpress.all.empty?
    Wordpress.all.each do |wordpress|
      @products = wordpress.get_products
      Product.import(@products, wordpress)
    end
    redirect_to product_types_path, notice: "Produtos importados."
  rescue
    redirect_to product_types_path, alert: "Falha ao importar, checar configurações do Wordpress."
  end
  
end
