class ProductTypeError < ActiveRecord::Base
  belongs_to :product_type

  def toggle_solved
    update(solved: !solved)
  end
end
