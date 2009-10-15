require 'rubygems'
require 'engine'
include Engine

class Timer < Text
	def initialize
		super(:text => " ")
		reset
	end
	
	def update
		@life -= 1
		@text = (@life/@@game.fps).to_s
		rerender
	end
	
	def reset
		@life = 15*@@game.fps
	end
	
	def destroy
		@@game.current_state.fail
	end
end

class Level < Text
	def initialize
		super(:text => "")
	end
end

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

class Door < GameObject
	def initialize
		super(:width => 16, :height => 32, :x => rand(@@screen.width), :y => rand(@@screen.height), :depth => 1)
		@surface = Rubygame::Surface.new [@width, @height]
		@surface.draw_box [0,0], [@width-1, @height-1], [220,0,0]
		
		# Create the box the door sits on,
		# and make sure it doesn't kill
		# itself
		@box = Green.new(@x-@width/2,@y+@height-1)
		def @box.update
		end
	end
	
	def draw
		@surface.blit @@screen, [@x, @y]
	end
	
	def destroy
		@box.life = 0
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
			if @y-@yvel >= obj.y + obj.height and @x+@width > obj.x and @x < obj.x+obj.width
				@y = obj.y+obj.height
				@yvel = 0
			end
		end
		if obj.class == Door
			#@@game.switch_state Win.new
			@@game.current_state.level_up
		end
	end
end

class InGame < State
	def setup
		@level = 0
		@player = Player.new
		@door = Door.new
		@timer = Timer.new
	end
	
	def update
		greens = @objs.select do |obj|
			obj.class == Green
		end
		Green.new rand(@@screen.width-32), rand(@@screen.height-32) if greens.length < @level*5
	end
	
	def level
		@level
	end
	
	def level_up
		@level += 1
		@timer.reset
		
		@player.life = 0
		@door.life = 0
		greens = @objs.select do |obj|
			obj.class == Green
		end
		greens.each { |obj| obj.life = 0 }
		
		@player = Player.new
		@door = Door.new
	end
	
	def fail
		@level = 0
		@timer = Timer.new
		
		@player.life = 0
		@door.life = 0
		greens = @objs.select do |obj|
			obj.class == Green
		end
		greens.each { |obj| obj.life = 0 }
		
		@player = Player.new
		@door = Door.new
	end
end

class WinText < Text
	def initialize
		super(:text => "Win", :size => 380, :depth => 5)
		@life = 255
		center
	end
	
	def update
		@life -= 5
		@color.length.times { |c| @color[c] = @life }
		@depth = @life
		rerender
	end
end

# Start the game!
game = Game.new :title => "Green", :width => 640, :height => 480, :fps => 30
game.key_press(Rubygame::K_ESCAPE, lambda {Rubygame.quit ; exit}, game)
game.switch_state InGame.new
game.run
