class Product < ActiveRecord::Base
  has_many :product_types, dependent: :destroy
  belongs_to :wordpress

  def self.import(products_data, wordpress)
    products_data.each do |data|
      #Criando produto
      product = wordpress.products.find_or_create_by(id_at_wordpress: data["id"],
                                                    name: data["title"],
                                                    link: data["permalink"])
      #Criando opções
      if data['variations'].any?
        data['variations'].each do |variation|
          attributes = variation['attributes'][0]
          name = [attributes['name'], attributes['option']].join(' ')
          ProductType.find_or_create_by(product: product,
                                        name: name,
                                        id_at_wordpress: variation['id'])
        end
      else
        ProductType.find_or_create_by(product: product,
                                      name: 'Único',
                                      id_at_wordpress: product.id_at_wordpress)
      end
    end
  end
end
