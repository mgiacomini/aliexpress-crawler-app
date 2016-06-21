require 'csv'
require 'pry'

module Aliexpress
  class Links
    def initialize file
      @file = file
      @links = self.import
    end

    #Importa planilha normalizando os dados
    def import
      links = []
      CSV.foreach(@file, headers: true, skip_blanks: true) do |row|
        data = row.to_hash
        unless (link = data["link"]).nil?
          link.downcase!
          link.strip!
        end
        unless (product_link = data["product_link"]).nil?
          product_link.gsub!(" ‎","")
          product_link.downcase!
          product_link.concat("/") unless product_link.end_with?"/"
        end
        links << data
      end
      links
    end

    #Obtém a linha da planilha usando o product_link
    def find_item product_link
      @links.find{|l| l['product_link'] == product_link}
    rescue
      p "Erro ao procurar produto #{product_link} na planilha."
    end
  end
end
