class Product < ActiveRecord::Base
  has_many :product_types, dependent: :destroy
  belongs_to :wordpress

  def self.import(products_data, wordpress)
    products_data.each do |data|
      #Criando produto
      products = wordpress.products
      product = products.find_or_initialize_by(id_at_wordpress: data["id"])
      product.name = data['name']
      product.link = data['permalink']
      product.save

      #Criando opções
      attributes = data['attributes']
      product_types = product.product_types
      if attributes.none?
        product_type = product_types.find_or_create_by(name: 'unico')
      else
        number_of_attributes = attributes.count

        if number_of_attributes == 1
          variations = data['attributes'].first['options']
        else
          options = data['attributes'].map {|a| a['options']}
          first_attribute_options = options[0]
          second_attribute_options = options[1]
          variations = first_attribute_options.product(second_attribute_options)
          variations = variations.map { |o| o.join(' ') }
          if number_of_attributes == 3
            third_attribute_options = options[2]
            variations = variations.product(third_attribute_options)
            variations = variations.map { |o| o.join(' ') }
          end
        end

        variations.each do |option|
          name = option.present? ? option : 'unico'
          product_type = product_types.find_or_create_by(name: name)
        end
      end
    end
  end
end
