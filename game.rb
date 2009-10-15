#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'

require 'dev/engine'
include Engine

class GameObject
	def flicker
		@@screen.draw_box_s([@x+rand(@width+8)-10, @y+rand(@height+8)-10], [@x+rand(@width+8), @y+rand(@height+8)], [0, 0, 0])
	end
end

class Timer < Text
	def initialize
		super(:text => " ", :depth => 5, :font => 'media/FreeSans.ttf')
		reset
	end
	
	def update
		@life -= 1
		@text = (@life/@@game.fps).to_s
		rerender
	end
	
	def draw
		super
		flicker
	end
	
	def reset time=15
		@life = time*@@game.fps
	end
	
	def destroy
		@@game.current_state.fail
	end
end

class Level < Text
	def initialize
		super(:text => " ", :x => @@screen.width-50, :depth => 5, :font => 'media/FreeSans.ttf')
	end
	
	def draw
		super
		flicker
	end
end

class Green < GameObject
	def initialize x=0, y=0
		super(:width => 32, :height => 32, :x => x, :y => y, :depth => rand(3))
		@surface = Rubygame::Surface.new [@width, @height]
		@surface.draw_box [0,0], [@width-1, @height-1], [0,220,0]
		@life = rand(200)+1
	end
	
	def draw
		@surface.draw_box [0,0], [@width-1, @height-1], [0,220-rand(100),0] if rand(50) == 0
		@surface.blit @@screen, [@x, @y]
		flicker
	end
	
	def update
		@life -= 1
	end
end

class Door < GameObject
	def initialize x=rand(@@screen.width-50)+25, y=rand(@@screen.height-100)+25
		super(:width => 16, :height => 32, :x => x, :y => y, :depth => 1)
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
		flicker
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
			@@game.current_state.level_up
		end
	end
end

class InGame < State
	attr_accessor :flicker
	
	def setup
		escape = lambda do
			File.open('config.yml', 'w') { |f| f.puts YAML.dump(@conf) }
			Rubygame.quit
			exit
		end
		music = lambda do
			if @music.playing?
				@music.pause
			else
				@music.unpause
			end
			
		end
		@@game.key_press(Rubygame::K_ESCAPE, escape, self)
		@@game.key_press(Rubygame::K_M, music, self)
		
		@level = 0
		@player = Player.new
		@door = Door.new 200, 200
		@timer = Timer.new
		@timer.reset(60)
		@lev_text = Level.new
		@lev_text.text = @level.to_s
		@background = Image.new :image => 'media/intro.png'
		@music = Rubygame::Music.load 'media/song.ogg'
		@music.play
		
		@conf = YAML.load(File.read('config.yml'))
		@@screen.title = "To The Exit... Again - High Score: #{@conf[:high_score]}"
	end
	
	def update
		@music.play if @music.stopped?
		greens = @objs.select do |obj|
			obj.class == Green
		end
		(@level*5-greens.length).times do |i|
			Green.new rand(@@screen.width-32), rand(@@screen.height-32)
			break if i > 5
		end
	end
	
	def level
		@level
	end
	
	def level_up
		@level += 1
		if @level > @conf[:high_score]
			@conf[:high_score] = @level
			@@screen.title = "To The Exit... Again - High Score: #{@conf[:high_score]}"
		end
		@lev_text.text = @level.to_s
		@timer.reset if @level <= 20
		@timer.reset(10) if @level >= 21
		@timer.reset(5) if @level >= 40
		@background.life = 0
		
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
		@lev_text.text = @level.to_s
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

# Start the game!
game = Game.new :title => "To The Exit... Again", :width => 640, :height => 480, :fps => 30
game.switch_state InGame.new
game.run
