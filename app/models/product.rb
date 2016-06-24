class Product < ActiveRecord::Base
  def self.import products, wordpress
    products.each do |data|
      product = find_by_wordpress_id(data["id"]) || new
      product.update(wordpress_id: data["id"],
                     name: data["title"],
                     link: data["permalink"],
                     store: wordpress.name)
      product.save!
    end
  end
end
