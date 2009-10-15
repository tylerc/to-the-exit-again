require 'rubygems'
require 'engine'
include Engine

class Green < GameObject
	def initialize x=0, y=0
		super(:width => 32, :height => 32, :x => x, :y => y, :depth => rand(3))
		@surface = Rubygame::Surface.new [@width, @height]
		@surface.draw_box [0,0], [@width-1, @height-1], [0,220,0]
		@life = 100
	end
	
	def draw
		@surface.draw_box [0,0], [@width-1, @height-1], [0,220-rand(100),0] if rand(50) == 0
		@surface.blit @@screen, [@x, @y]
		@@screen.draw_box_s [@x+rand(@width+8)-10, @y+rand(@height+8)-10], [@x+rand(@width+8), @y+rand(@height+8)], [0, 0, 0]
	end
	
	def update
		@life -= 1
	end
end

class Player < Box
	def initialize
		super :width => 16, :height => 32, :x => @@screen.width/2-10, :y => @@screen.height-50, :depth => 1
		
		@speed = 10
		@col_left = false
		@col_right = false
		@col_top = false
		@gravity = 1
		@yvel = 0
		@hit = false
		
		@@game.key_press(Rubygame::K_UP, lambda { @yvel -= 10 }, self)
		@@game.while_key_down(Rubygame::K_LEFT, lambda { unless @col_right ; @x -= @speed ; end }, self)
		@@game.while_key_down(Rubygame::K_RIGHT, lambda { unless @col_left ; @x += @speed ; end }, self)
		@@game.key_press(Rubygame::K_E, lambda { eval gets }, self)
		
		@surface = Rubygame::Surface.new [@width,@height]
		@surface.draw_box [0,0], [@width-1,@height-1], @color
	end
	
	def update
		unless @y+@height >= @@screen.height and !@col_top
			@yvel += @gravity
			@hit = false
		end
		@y += @yvel
		if @y+@height >= @@screen.height and @yvel >= 0
			if @hit == false
				@hit = true
				@yvel = 0
			end
			@y = @@screen.height-@height
		end
		@col_left = false
		@col_right = false
		@col_top = false
	end
	
	def collision obj
		if obj.class == Green
			# Left
			#if @x+@width-@speed <= obj.x 
			#	@x = obj.x-@width
			#	@col_left = true
			#end
			# Right
			#if  @x+@speed >= obj.x+obj.width# and @y+@height >= obj.y+obj.height
			#	@x = obj.x+obj.width
			#	@col_right = true
			#end
			# Top
			if @y+@height-@yvel <= obj.y and @x+@width > obj.x and @x < obj.x+obj.width
				if @hit == false
					@hit = true
					@yvel = 0
				end
				@col_top = true
				@y = obj.y-@height
			end
			# Bottom
			#if @y-@yvel >= obj.y + obj.height and @x+@width > obj.x and @x < obj.x+obj.width
			#	@y = obj.y+obj.height
			#	@yvel = 0
			#end
		end
	end
end

class InGame < State
	def setup
		Player.new
=begin
		space = 32
		(640/space).times do |x|
			Green.new x*space, 0
		end
		(640/space).times do |x|
			Green.new x*space, @@screen.height-32
		end
		(480/space).times do |y|
			Green.new 0, y*space
		end
		(480/space).times do |y|
			Green.new @@screen.width-32, y*space
		end
=end
	end
	
	def update
		Green.new rand(@@screen.width-32), rand(@@screen.height-32)
	end
end

# Start the game!
game = Game.new :title => "Green", :width => 640, :height => 480, :fps => 30
game.key_press(Rubygame::K_ESCAPE, lambda {Rubygame.quit ; exit}, game)
game.switch_state InGame.new
game.run
