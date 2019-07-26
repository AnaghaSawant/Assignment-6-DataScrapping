require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'byebug'

class Parsing
	attr_accessor :all_category, :all_recipes, :allrecipes_dirctions, :allrecipes_pretime, :allrecipes_readytime, :allrecipes_cooktime

	def initialize
		@all_category = []
		@all_recipes = []
		@all_recipes_info = []
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
		puts "in recipes"
		@all_category.each do |i|
			cat_link = Nokogiri::HTML(open(i[:link]))
			rec_name = cat_link.to_html.scan(/(?<=(<span class="fixed-recipe-card__title-link">))(.*)(?=(<\/span>))/)
			rec_link = cat_link.to_html.scan(/<h3\s*class="fixed-recipe-card__h3\">\s*<a\s*href=\"(.*?)\"/)
			rec_names = []
			rec_links = []
			counter = 0
			count = 0

			rec_name.each do |name|
				if counter <= 9
					nam = name[1].gsub("\"","\'")
					rec_names.push(nam)
					counter = counter + 1
				end
			end
			
			rec_link.each do |link|
				if count <= 9
					li = link.join("")
					rec_links.push(li)
					count = count + 1
				end
			end
			rec_names.each_with_index do |rec_name, index|
				rec_hash = {
								name: rec_name,
								link: rec_links[index]
							}
							@all_recipes.push(rec_hash)
			end
		end
		puts @all_recipes
		# @all_recipes.each do |item|
		# 	puts item[:name]
		# end
	end
		
	def parsing_recipes_info
		puts "in recipes info"
		@all_recipes_ingredients = []
		@allrecipes_dirctions = []
		@allrecipes_pretime = []
		@allrecipes_cooktime = []
		@allrecipes_readytime = []

		@all_recipes.each do |i|
			temp_ing = Array.new
			temp_direct = Array.new
			my_link = i[:link]
			# puts my_link.class
			recipe_link = Nokogiri::HTML(open(my_link))
			rec_ingredient = recipe_link.to_html.scan(/(?<=(itemprop="recipeIngredient">))(.*)(?=(<\/span>))/)
			rec_direction = recipe_link.to_html.scan(/<span\s*class="recipe-directions__list--item\">\s*(.*?)\s*<\/span>/)
			prepare_time = recipe_link.to_html.scan(/<time\s*itemprop="prepTime"\s\w*=\"\w*\"><span\s*aria-hidden="true\"><span\s*class=\"prepTime__item--time\">\s*(.*?)<\/span>\s*(.?)<\/span><\/time>/)
			cook_time = recipe_link.to_html.scan(/<time\s*itemprop="cookTime"\s\w*=\"\w*\"><span\s*aria-hidden="true\"><span\s*class=\"prepTime__item--time\">\s*(.*?)<\/span>\s*(.?)<\/span><\/time>/)
	    ready_time = recipe_link.to_html.scan(/<time\s*itemprop="totalTime"\s\w*=\"\w*\"><span\s*aria-hidden="true\"><span\s*class=\"prepTime__item--time\">\s*(.*?)<\/span>\s*(.?)<\/span><\/time>/)
			
	    rec_direction.each do |direct|
	    	# byebug
	    	directions = direct.join("").gsub(/,/,"")
	    	directs = directions.gsub("\'","\"")
	    	temp_direct.push(directs)
	    	# temp_direct.map { |e| e.gsub(/,/,"")}
	    end

			rec_ingredient.each do |ingred|
				temp_ing.push(ingred[1])
			end

			@allrecipes_pretime.push(prepare_time)
			@allrecipes_cooktime.push(cook_time)
			@allrecipes_readytime.push(ready_time)
			@all_recipes_ingredients.push(temp_ing)	
			@allrecipes_dirctions.push(temp_direct)
		end

		# byebug
		# @all_recipes.each_with_index do |reci_name, index|
		# 	byebug
		# 	rec_info = {
		# 		recipename: reci_name,
		# 		recing: all_recipes_ingredients[index],
		# 		recdir: allrecipes_dirctions[index],
		# 		recpre: allrecipes_pretime[index],
		# 		reccook: allrecipes_cooktime[index],
		# 		recready: allrecipes_readytime[index]
		# 	}
		# 	@all_recipes_info.push(rec_info)
		# end
		puts "================"
		
		# puts @all_recipes_info
	end

end

class DbConnection
	attr_accessor :parsed

	def initialize
		@parsed = Parsing.new
		@parsed.parcing_categories
		@parsed.parsing_recipes
		@parsed.parsing_recipes_info
		puts @allrecipes_pretime
		@db = SQLite3::Database.new 'allrecipes.db'
	end

	def insert_categories
		@db.execute "DROP TABLE IF EXISTS allcategories"
	  @db.execute "CREATE TABLE allcategories(Id INTEGER PRIMARY KEY, Name TEXT,  Link TEXT)"

		@parsed.all_category.each do |i|
			@db.execute("INSERT INTO allcategories(Name, Link) VALUES('#{i[:name]}',  '#{i[:link]}')")
		end
	end


	def insert_recipes
		id = 1
		count = 1
		counter = 1
		identy = 1
		@db.execute "DROP TABLE IF EXISTS allrecipes"
		@db.execute "CREATE TABLE allrecipes(Id INTEGER PRIMARY KEY,Recipename TEXT, Recipelink TEXT, RecipeDirection array, RecipePreTime TEXT, RecipeCookTime TEXT, RecipeReadyIn TEXT)"

		@parsed.all_recipes.each do |i|
			# byebug
			@db.execute('INSERT INTO allrecipes(Recipename, Recipelink) VALUES("'"#{i[:name]}"'", "'"#{i[:link]}"'")')
    end

    @parsed.allrecipes_dirctions.each do |i|
    	@db.execute("UPDATE allrecipes SET RecipeDirection = '#{i}' where Id = '#{id}'")
    	id = id + 1;
    end

    @parsed.allrecipes_pretime.each do |o|
    	@db.execute("UPDATE allrecipes SET RecipePreTime = '#{o}' where Id = '#{count}' ")
    	count = count + 1;
    end

    @parsed.allrecipes_cooktime.each do |o|
    	@db.execute("UPDATE allrecipes SET RecipeCookTime = '#{o}' where Id = '#{counter}' ")
    	counter = counter + 1;
    end

    @parsed.allrecipes_readytime.each do |o|
    	@db.execute("UPDATE allrecipes SET RecipeReadyIn = '#{o}' where Id = '#{identy}' ")
    	identy = identy + 1;
    end

	end
end

db = DbConnection.new
db.insert_categories
db.insert_recipes

# "https":"https":"https":