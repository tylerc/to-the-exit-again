require 'rubygems'
require 'engine'
include Engine

class Green < GameObject
	def initialize x=0, y=0
		super(:width => 32, :height => 32, :x => x, :y => y)
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

class InGame < State
	def setup
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
