require 'rubygame'
Rubygame::TTF.setup

# Is a nice (hopefully) wrapper around Rubygame that should help
# make game development even easier!
#
# You can use it's API by using: require 'engine' in your code.
#
# You can see an example of its functionality in action by running
# engine.rb directly with:
#  ruby -rubygems lib/engine_example.rb
#
# Notes about how the code looks:
# * the variable obj is used as shorthand when we iterate over game objects
# * the variable s is used for settings that have the defaults applied to them
#
# There aren't really any other code-style guides, we'll be pretty happy with
# what ever you feel like naming your variables
module Engine
	# This is the Game class, it contains everything you need
	# to create your game
	#
	# For events (key_press, mouse_motion, etc.):
	# Takes:
	# * The key/button pressed (Rubygame::K_KEY)
	# * The code to run 
	#   * either: lambda { |pos| # code here } 
	#   * or: method(:name_of_method)
	# * The owner of the event. 
	#   * If it is the Game object, it is never destroyed (until the game ends)
	#   * If it is a State object, it is only active when the state is
	#   * If it is a GameObject, it is destroyed when the GameObject is destroyed
	class Game
		# The screen we're drawing to
		attr_reader :screen
		# The state the game is in/using
		attr_reader :current_state
		# Game's FPS
		attr_reader :fps
		
		# Creates a new game
		#
		# Parameters are in hash format (i.e. Game.new(:width => 640, :height =. 480) )
		#
		# Takes:
		# * Window Width (:width)
		# * Window Height (:height)
		# * Flags (:flags) (best left at defaults)
		# * Window Title (:title)
		# * Desired Frames per Second (:fps)
		def initialize(settings={:width => 640, :height => 480, :flags => [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF], :title => "Game Engine Window", :fps => 30})
			s = {:width => 640, :height => 480, :flags => [Rubygame::HWSURFACE, Rubygame::DOUBLEBUF], :title => "Game Engine Window", :fps => 30}.merge(settings)
			@fps = s[:fps]
			@screen = Rubygame::Screen.new [s[:width], s[:height]], 0, s[:flags]
			@screen.title = s[:title]
		
			@queue = Rubygame::EventQueue.new
			@clock = Rubygame::Clock.new
			@clock.target_framerate = s[:fps]
			
			GameObject.add_to_game self
			State.add_to_game self
			
			@current_state = State.new
			@states = []
			@objs2 = []
			@global_events = {:key_press => [], :key_release => [], :mouse_press => [], :mouse_release => [], :mouse_motion => [], :while_key_down => [], :while_key_up => []}
		end
		
		# Adds objects to the game
		#
		# GameObjects do this for you
		#--
		# Adds the new objects to @objs2 so we don't add an object while iterating over it
		def add obj
			@objs2 += [obj] 
		end
		
		# Main Loop
		def run
			loop do
				update
				draw
				@clock.tick
			end
		end
		
		# * Cleans up objects + their events, if their life == 0
		# * Handles and delegates events to objects
		# * Runs each objects update function
		def update
			@current_state.objs.each do |obj|
				if obj.life <= 0
					obj.destroy
					@current_state.objs.delete obj
					@current_state.events.each_key do |event|
						@current_state.events[event].each do |x|
							if x.owner == obj
								@current_state.events[event].delete x
							end
						end
					end
				end
			end
			
			@current_state.objs.each do |obj|
				@current_state.objs[@current_state.objs.index(obj)+1..-1].each do |obj2|
					unless collision_between(obj, obj2)
						next
					end
					obj.collision obj2
					obj2.collision obj
				end
			end
		
			@queue.each do |ev|
				case ev
					when Rubygame::QuitEvent
						Rubygame.quit
						exit
					when Rubygame::KeyDownEvent
						[@current_state.events, @global_events].each do |events|
							events[:key_press].each do |x|
								if ev.key == x.key
									x.call
								end
							end
					
							events[:while_key_down].each do |x|
								if ev.key == x.key
									x.active = true
								end
							end
					
							events[:while_key_up].each do |x|
								if ev.key == x.key
									x.active = false
								end
							end
						end
					when Rubygame::KeyUpEvent
						[@current_state.events, @global_events].each do |events|
							events[:key_release].each do |x|
								if ev.key == x.key
									x.call
								end
							end
						
							events[:while_key_down].each do |x|
								if ev.key == x.key
									x.active = false
								end
							end
						
							events[:while_key_up].each do |x|
								if ev.key == x.key
									x.active = true
								end
							end
						end
					when Rubygame::MouseDownEvent
						[@current_state.events, @global_events].each do |events|
							events[:mouse_press].each do |x|
								if ev.button == x.button
									x.call ev.pos
								end
							end
						end
					when Rubygame::MouseUpEvent
						[@current_state.events, @global_events].each do |events|
							events[:mouse_release].each do |x|
								if ev.button == x.button
									x.call ev.pos
								end
							end
						end
					when Rubygame::MouseMotionEvent
						[@current_state.events, @global_events].each do |events|
							events[:mouse_motion].each do |x|
								x.call ev.pos, ev.rel, ev.buttons
							end
						end
				end

			end
			
			@current_state.events[:while_key_down].each do |x|
				if x.active
					x.call
				end
			end
			@global_events[:while_key_down].each do |x|
				if x.active
					x.call
				end
			end
			
			@current_state.events[:while_key_up].each do |x|
				if x.active
					x.call
				end
			end
			@global_events[:while_key_up].each do |x|
				if x.active
					x.call
				end
			end
		
			@current_state.objs.each do |obj|
				obj.update
			end
			
			@current_state.update
			
			@current_state.objs += @objs2
			@current_state.objs.sort! { |a,b| (a.depth or 0) <=> (b.depth or 0) } unless @objs2.empty? # Sort by depth
			@objs2 = []
		end
		
		# Draws the screen
		def draw
			@screen.fill [0,0,0]
			
			@current_state.objs.each do |obj|
				obj.draw
			end
		
			@screen.flip
		end

		# Attaches a Key Press event
		def key_press *args
			event(:key_press, *args)
		end
		
		# Attaches a Key Release Event
		def key_release *args
			event(:key_release, *args)
		end
		
		# Attaches an event for while a key is down
		def while_key_down *args
			event(:while_key_down, *args)
		end
		
		# Attaches an event for while a key is up
		def while_key_up *args
			event(:while_key_up, *args)
		end
		
		# Attaches an event for when the mouse moves
		# Omit the button for this method
		def mouse_motion *args
			event(:mouse_motion, nil, *args)
		end
		
		# Attaches an event for when a mouse button is pressed
		def mouse_press *args
			event(:mouse_press, *args)
		end
		
		# Attaches an event for when a mouse button is released
		def mouse_release *args
			event(:mouse_release, *args)
		end
		
		def event(name, key, code, owner) #:nodoc:
			ev = Event.new(key, code, owner)
			if owner == self
				@global_events[name] += [ev]
			else
				@current_state.events[name] += [ev]
			end
			return ev
		end
		
		# Switches the state and destroys the current state
		#
		# Takes a state class (initialized) as an argument
		def switch_state state
			@objs2 = []
			@current_state = state
			@current_state.setup
		end
		
		# Pops a state off the state stack and makes it the current state. (This destroys the current state)
		def pop_state
			@objs2 = []
			@current_state = @states.pop
		end
		
		# Pushes a new state onto the state stack
		#
		# Takes a state class (initialized) as an argument
		def push_state state
			@objs2 = []
			@states.push @current_state
			@current_state = state
			@current_state.setup
		end
		
		# Returns true if there is a collision
		# false is there isn't
		#
		# Works on Engine::GameObject instances
		def collision_between obj1, obj2
			if obj1.y + obj1.height < obj2.y ; return false ; end
			if obj1.y > obj2.y + obj2.height ; return false ; end
			if obj1.x + obj1.width < obj2.x ; return false ; end
			if obj1.x > obj2.x + obj2.width ; return false ; end
			return true
		end
	end
	
	# Almost all objects should inherit from this
	#
	# All GameObjects understand the concepts of:
	# * Life - when this reaches 0 the GameObject is deleted by the Engine
	# * x and y positions on the screen
	# * width and height - Used for collision detection
	# * Depth - What's drawn on top of what. Lower the number, the lower it's drawn. Default is zero
	#
	# Take a careful look at the settings GameObject provides,
	# nowhere will the documentation repeat the basic options, so
	# you have to remember them
	class GameObject
		attr_accessor :x, :y, :width, :height, :depth
		# When life reaches zero, it is destroyed by the game engine
		attr_accessor :life
		
		# Creates a new GameObject.
		#
		# Parameters are in hash format (i.e. GameObject.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * x position (:x)
		# * y position (:y)
		# * width (:width)
		# * height (:height)
		# * Life (:life)
		# * Depth (:depth)
		def initialize settings={:x => 0, :y => 0, :width => 0, :height => 0, :life => 1, :depth => 0}
			s = {:x => 0, :y => 0, :width => 0, :height => 0, :life => 1, :depth => 0}.merge! settings
			Util.hash_to_var(s, [:x, :y, :width, :height, :life, :depth], self)
			@@game.add self
		end
		
		# Object's logic goes here
		def update
		end
		
		# Called every frame, only draw in here, no game logic
		def draw
		end
		
		# Method run when object is destroyed	
		def destroy
		end
		
		# Gives GameObjects access to the Game object
		def self.add_to_game game
			@@game = game
			@@screen = game.screen
		end
		
		# Method run when a collision occurs
		def collision obj
		end
		
		# returns the horizantal distance if you moved at that angle, for that distance
		def x_offset angle, distance
			distance * Math.sin(angle * Math::PI/180)
		end
		
		# returns the vertical distance if you moved at that angle, for that distance
		def y_offset angle, distance
			distance * Math.cos(angle * Math::PI/180) * -1
		end
		
		# Centers the object in the middle of the screen
		def center
			center_x
			center_y
		end
		
		# Centers along the x axis
		def center_x
			@x = @@screen.width/2-@width/2
		end
		
		# Centers along the y axis
		def center_y
			@y = @@screen.height/2-@height/2
		end
		
		# Find distance between two objects (a^2 + b^2 = c^2)
		def distance obj
			a = obj.x-@x
			b = obj.y-@y
			c = Math.sqrt(a**2 + b**2)	
		end
	end
	
	# For when you need something that won't last long, but still looks like a GameObject
	#
	# (useful for certain collision-detection situations)
	class ScapeGoat < Engine::GameObject
		def initialize settings={:width => 1, :height => 1}
			s = {:width => 1, :height => 1}.merge!(settings)
			super(s)
		end
		
		def update
			@life = 0
		end
	end
	
	# A Simple 2D box class
	class Box < Engine::GameObject
		# The color of the box
		#
		# An array in RGB format: [R,G,B]
		attr_accessor :color
		
		# Creates a new Box
		#
		# Parameters are in hash format (i.e. Box.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * Box Width (:width)
		# * Box Height (:height)
		# If Box is to be rotated/zoomed:
		# * Angle (:rot_angle)
		# * Zoom (:zoom)
		# * Anti-Alias (:aa)
		def initialize settings={:width => 20, :height => 20, :color => [255, 255, 255], :angle => 0, :zoom => 1, :aa => false}
			s = {:width => 20, :height => 20, :color => [255, 255, 255], :angle => 0, :zoom => 1, :aa => false}.merge!(settings)
			super s
			@surface = Rubygame::Surface.new [@width, @height]
			Util.hash_to_var(s, [:color, :zoom, :aa, :angle], self)
			@surface.fill @color
		end
		
		def draw
			if @angle == 0
				@surface.rotozoom(@angle,@zoom,@aa).blit @@screen, [@x, @y]
			else
				roted_surf = @surface.rotozoom(@angle,@zoom,@aa)
				x = @x.to_f+@width/2-roted_surf.w/2
				y = @y.to_f+@height/2-roted_surf.h/2
				roted_surf.blit @@screen, [x, y]
			end
		end
		
		def angle
			@angle
		end
		
		def angle= opt
			@angle = opt
		end
		
		def zoom
			@zoom
		end
		
		def zoom= opt
			@zoom = opt
		end
		
		def aa
			@aa
		end
		
		def aa= opt
			@aa = opt
		end
	end
	
	# A simple image class
	class Image < Engine::GameObject
	
		# Creates a new Image
		#
		# Parameters are in has format (i.e. Image.new(:x => 40, :y => 200) )
		#
		# Takes:
		# * Image File or rubygame Surface (:image) *REQUIRED*
		def initialize settings={}
			@surface = Rubygame::Surface.load settings[:image] if settings[:image].class == String
			@surface = settings[:image] if settings[:image].class == Rubygame::Surface
			settings[:width] = @surface.width
			settings[:height] = @surface.height
			super settings
		end
		
		def draw
			@surface.blit @@screen, [@x, @y]
		end
	end
	
	# A class used to display texts
	class Text < Engine::GameObject
		# Creates a new Text object
		#
		# Parameters are in hash format (i.e. Text.new(:x => 30, :y => 500) )
		#
		# Takes:
		# * the text to display (:text)
		# * Color (:color)
		# * Anti-Aliasing (true or false) (:aa)
		# * Font Size (:size)
		# * Font file to use (must be ttf) (:font)
		def initialize settings={:text => "TEST STRING", :color => [255, 255, 255], :aa => true, :size => 20, :font => "FreeSans.ttf"}
			s = {:text => "TEST STRING", :color => [255, 255, 255], :aa => true, :size => 20, :font => "FreeSans.ttf"}.merge settings
			@font = Rubygame::TTF.new s[:font], s[:size]
			s[:width] = @font.size_text(s[:text])[0]
			s[:height] = @font.size_text(s[:text])[1]
			super s
			
			Util.hash_to_var(s, [:text, :color, :aa], self)
			rerender
		end
		
		def draw
			@surface.blit @@screen, [@x,@y]
		end
		
		def text
			@text
		end
		
		def text= string
			@text = string
			rerender
		end
		
		def rerender
			@width = @font.size_text(@text)[0]
			@height = @font.size_text(@text)[1]
			@surface = @font.render(@text, @aa, @color)
		end
		
		def aa
			@aa
		end
		
		def aa= opt
			@aa = opt
			rerender
		end
		
		def color
			@color
		end
		
		def color= opt
			@color = opt
			rerender
		end
	end
	
	# This class is used interally by the Game class
	#
	# This class is used for both mouse button presses and keyboard keypresses.
	# There is no distinction of this in the Event class. The distinction is
	# made in the Game class
	class Event
		attr_reader :owner, :key
		attr_accessor :active
		alias :button :key
		# Creates a new event object
		#
		# Takes:
		# * The key or button we're working with
		# * The code to be run when the event happens
		# * The object that owns the event
		# * Whether it is active (i.e. for a while_key_down event)
		def initialize key, code, owner, active=false
			@key = key
			@code = code
			@owner = owner
			@active = active
		end
		
		# Runs the code specified in the event's creation
		def call *args
			@code.call *args
		end
	end
	
	# All game states should inherit from this class
	#
	# When defining your own state, all code should be in the setup method.
	# You should not overide anything unless you know what you are doing.
	#
	# Example:
	#  class MyState < Engine::State
	#  	def setup
	#  		mybox = Engine::Box.new :width => 30, :height => 30, :x => 200, :y => 400
	#  	end
	#  end
	class State
		# Events in the state
		attr_accessor :events
		# Objects in the state
		attr_accessor :objs
		
		# initializes the @events and @objs methods
		#
		# DO NOT OVERIDE THIS METHOD
		def initialize
			@events = {:key_press => [], :key_release => [], :mouse_press => [], :mouse_release => [], :mouse_motion => [], :while_key_down => [], :while_key_up => []}
			@objs = []
		end
		
		# Gives state objects access to the game class
		def self.add_to_game game
			@@game = game
			@@screen = game.screen
		end
		
		# Code that is run when a state takes the stage
		# override this method in your own states
		def setup
		end
		
		# If you want your state to run some code every update
		#
		# This helps keep down on useless objects =)
		def update
		end
	end
	
	# Utilities for internal use in the game engine
	class Util
		# Goes through a hash, and sets instance variables
		def self.hash_to_var(hash, filter, obj)
			filter.each do |var|
				obj.send :instance_variable_set, :"@#{var}", hash[var]
			end
		end
	end
end
