class Product < ActiveRecord::Base
  has_many :product_types
  def self.import products, wordpress
    products.each do |data|
      #Criando produtos
      product = find_by_wordpress_id(data["id"]) || new
      product.update(wordpress_id: data["id"],
      name: data["title"],
      link: data["permalink"],
      store: wordpress.name)
      #Criando opções
      product_types = data['attributes']
      if product_types.empty?
        product_type = ProductType.find_by(product: product, name: 'Único') || ProductType.new
        product_type.update(product: product, name: 'Único')
      else
        product_types[0]['options'].each do |name|
          product_type = ProductType.find_by(product: product, name: name) || ProductType.new
          product_type.update(product: product, name: name)
        end
      end
    end
  end
end
