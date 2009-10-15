require 'rubygems'
require 'engine'
include Engine

class Floor < GameObject
	def initialize
		super(:x => 0, :y => 0, :width => @@screen.width, :height => @@screen.height)
		@surface = Rubygame::Surface.new [@width, @height]
		@surface.fill [100, 25, 0]
	end
	
	def draw
		@surface.blit @@screen, [@x, @y]
	end
end

class InGame < State
	def setup
		Floor.new
	end
end

# Start the game!
game = Game.new :title => "Diner", :width => 640, :height => 480, :fps => 30
game.key_press(Rubygame::K_ESCAPE, lambda {Rubygame.quit ; exit}, game)
game.switch_state InGame.new
game.run
