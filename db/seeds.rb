# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
wordpress = Wordpress.create(name: "Biju Chique",
                 url: "http://bijuchique.com",
                 consumer_key: "ck_7c41a19e24c7f10ad43f9a212ca03409",
                 consumer_secret: "cs_0bf0e3bdee1bf8e20c0518e4065cd654")
aliexpress = Aliexpress.create(name: "Jessica",
                                email: "jessicams91@hotmail.com",
                                password: "claudiams")
Crawler.create(aliexpress: aliexpress, wordpress: wordpress)
