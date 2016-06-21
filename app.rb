lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'woocommerce_api'
require 'rubygems'
require 'aliexpress'

aliexpress = Aliexpress::API.new(
  "http://exemplo.com",   #Url do site
  "ck_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", #Consumer Key Wordpress
  "cs_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", #Consumer Secret Wordpress
  "livro.csv" #Nome da planilha
)
aliexpress.run(
  'user@email.com', #Email de usuário Aliexpress
  'password' #Senha Aliexpress
  )
