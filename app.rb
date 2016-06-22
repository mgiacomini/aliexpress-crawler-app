lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'woocommerce_api'
require 'rubygems'
require 'aliexpress'

aliexpress = Aliexpress::API.new(
"http://bijuchique.com", #Url do site
"ck_7c41a19e24c7f10ad43f9a212ca03409", #Consumer Key Wordpress
"cs_0bf0e3bdee1bf8e20c0518e4065cd654", #Consumer Secret Wordpress
"livro.csv" #Nome da planilha
)
aliexpress.run(
'jessicams91@hotmail.com', #Email de usuário Aliexpress
'claudiams' #Senha Aliexpress
)
