require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'sqlite3'

class Parsing
	attr_accessor :all_category

	def initialize
		@all_category = []
		@doc = Nokogiri::HTML(open("https://www.allrecipes.com/"))
	end

	def parcing_categories
		category_name = @doc.to_html.scan(/(?<=(class\=\"category-title\" data-ellipsis>))(.*)(?=(<\/span>))/)
		category_link = @doc.to_html.scan(/(?<=href\=)(["'])(.*?)\1(.*)(?=class="grid-col--subnav">)/)
		category_names = []
		category_links = []

		category_name.each do |cat_name|
			names = {
						name: cat_name[1]
					}
			category_names.push(names)
		end 

		category_link.each do |cat_link|
			links = {
				link: cat_link[1]
			}
			category_links.push(links)
		end
	
		category_names.each_with_index do |cat_name, index|
				hash = {
							name: cat_name,
							link: category_links[index]
						}
						@all_category.push(hash)
		end
		puts @all_category
	end

end

class DbConnection
	attr_accessor :parsed

	def initialize
		@parsed = Parsing.new
		@parsed.parcing_categories
	end

	def insert_categories
		db = SQLite3::Database.new 'allrecipes.db'
	    db.execute "CREATE TABLE allcategories(Id INTEGER PRIMARY KEY, Name TEXT,  Link TEXT)"

		@parsed.all_category.each do |i|
			db.execute("INSERT INTO allcategories(Name, Link) VALUES('#{i[:name]}',  '#{i[:link]}')")
		end
	end
end

db = DbConnection.new
db.insert_categories

