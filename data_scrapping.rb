require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'sqlite3'

class Parsing
	attr_accessor :all_category, :all_recipes

	def initialize
		@all_category = []
		@all_recipes = []
		@doc = Nokogiri::HTML(open("https://www.allrecipes.com/"))
	end

	def parcing_categories
		category_name = @doc.to_html.scan(/(?<=(class\=\"category-title\" data-ellipsis>))(.*)(?=(<\/span>))/)
		category_link = @doc.to_html.scan(/(?<=href\=)(["'])(.*?)\1(.*)(?=class="grid-col--subnav">)/)
		category_names = []
		category_links = []

		category_name.each do |cat_name|
			category_names.push(cat_name[1])
		end 

		category_link.each do |cat_link|
			category_links.push(cat_link[1])
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

	def parsing_recipes
		rec_names = []
		rec_links = []
		@all_category.each do |i|
			cat_link = Nokogiri::HTML(open(i[:link]))
			rec_name = cat_link.to_html.scan(/(?<=(<span class="fixed-recipe-card__title-link">))(.*)(?=(<\/span>))/)
			rec_link = cat_link.to_html.scan(/(?<=(<h3 class="fixed-recipe-card__h3">))(.*)(?=(<\/h3>))/m)
			rec_name.each do |name|
				rec_names.push(name[1])
			end

			rec_link.each do |link|
				# rec_links.push(link)
				link.each do |item|
					parsed_data = Nokogiri::HTML.parse(item)
					recipe_link = parsed_data.to_html.scan(/(?<=(href=))((\"[a-zA-z0-9\"]).*)(?=(data-content))/)
					recipe_link.each do |rec_ref|
						rec_links.push(rec_ref[1])
					end
				end
			end
		end
		rec_names.each_with_index do |rec_name, index|
				hash = {
							rec_name: rec_name,
							rec_link: rec_links[index]
						}
						@all_recipes.push(hash)
		end
		puts @all_recipes
	end
end

class DbConnection
	attr_accessor :parsed

	def initialize
		@parsed = Parsing.new
		@parsed.parcing_categories
		@db = SQLite3::Database.new 'allrecipes.db'
	end

	def insert_categories
		@db.execute("DROP TABLE IF EXISTS allcategories")
	    @db.execute "CREATE TABLE allcategories(Id INTEGER PRIMARY KEY, Name TEXT,  Link TEXT)"

		@parsed.all_category.each do |i|
			@db.execute("INSERT INTO allcategories(Name, Link) VALUES('#{i[:name]}',  '#{i[:link]}')")
		end
	end
end

db = DbConnection.new
db.insert_categories

