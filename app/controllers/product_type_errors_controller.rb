class ProductTypeErrorsController < ApplicationController
  def index
    @errors = ProductTypeError.order(solved: :asc, occurrences: :desc)
  end

  def destroy
    @error = ProductTypeError.find(params[:id])

    if @error.destroy
      flash[:notice] = 'Removido com sucesso'
    else
      flash[:alert] = 'Falha ao remover'
    end

    redirect_to product_type_errors_path
  end

  def toggle_solved
    error = ProductTypeError.find(params[:product_type_error_id])

    if error.toggle_solved
      flash[:notice] = 'Alterado com sucesso'
    else
      flash[:alert] = 'Falha ao alterar'
    end

    redirect_to product_type_errors_path
  end
end
