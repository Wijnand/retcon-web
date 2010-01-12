module Cell
  # == Basic overview
  #
  # A Cell is the central notion of the cells plugin.  A cell acts as a
  # lightweight controller in the sense that it will assign variables and
  # render a view.  Cells can be rendered from other cells as well as from
  # regular controllers and views (see ActionView::Base#render_cell and
  # ControllerMethods#render_cell)
  #
  # == A render_cell() cycle
  #
  # A typical <tt>render_cell</tt> state rendering cycle looks like this:
  #   render_cell :blog, :newest_article, {...}
  # - an instance of the class <tt>BlogCell</tt> is created, and a hash containing
  #   arbitrary parameters is passed
  # - the <em>state method</em> <tt>newest_article</tt> is executed and assigns instance 
  #   variables to be used in the view
  # - if the method returns a string, the cycle ends, rendering the string
  # - otherwise, the corresponding <em>state view</em> is searched.
  #   Usually the cell will first look for a view template in
  #   <tt>app/cells/blog/newest_article.html. [erb|haml|...]</tt>
  # - after the view has been found, it is rendered and returned
  #
  # It is common to simply return <tt>nil</tt> or call #render in state methods to advice the cell to
  # render the corresponding template.
  #
  # == Design Principles
  # A cell is a completely autonomous object and it should not know or have to know
  # from what controller it is being rendered.  For this reason, the controller's
  # instance variables and params hash are not directly available from the cell or
  # its views. This is not a bug, this is a feature!  It means cells are truly
  # reusable components which can be plugged in at any point in your application
  # without having to think about what information is available at that point.
  # When rendering a cell, you can explicitly pass variables to the cell in the
  # extra opts argument hash, just like you would pass locals in partials.
  # This hash is then available inside the cell as the @opts instance variable.
  #
  # == Directory hierarchy
  #
  # To get started creating your own cells, you can simply create a new directory
  # structure under your <tt>app</tt> directory called <tt>cells</tt>.  Cells are
  # ruby classes which end in the name Cell.  So for example, if you have a
  # cell which manages all user information, it would be called <tt>UserCell</tt>.
  # A cell which manages a shopping cart could be called <tt>ShoppingCartCell</tt>.
  #
  # The directory structure of this example would look like this:
  #   app/
  #     models/
  #       ..
  #     views/
  #       ..
  #     helpers/
  #       application_helper.rb
  #       product_helper.rb
  #       ..
  #     controllers/
  #       ..
  #     cells/
  #       shopping_cart_cell.rb
  #       shopping_cart/
  #         status.html.erb
  #         product_list.html.erb
  #         empty_prompt.html.erb
  #       user_cell.rb
  #       user/
  #         login.html.erb
  #       layouts/
  #         box.html.erb
  #     ..
  #
  # The directory with the same name as the cell contains views for the
  # cell's <em>states</em>.  A state is an executed method along with a
  # rendered view, resulting in content. This means that states are to
  # cells as actions are to controllers, so each state has its own view.
  # The use of partials is deprecated with cells, it is better to just
  # render a different state on the same cell (which also works recursively).
  #
  # Anyway, <tt>render :partial </tt> in a cell view will work, if the 
  # partial is contained in the cell's view directory.
  #
  # As can be seen above, Cells also can make use of helpers.  All Cells
  # include ApplicationHelper by default, but you can add additional helpers
  # as well with the Cell::Base.helper class method:
  #   class ShoppingCartCell < Cell::Base
  #     helper :product
  #     ...
  #   end
  #
  # This will make the <tt>ProductHelper</tt> from <tt>app/helpers/product_helper.rb</tt>
  # available from all state views from our <tt>ShoppingCartCell</tt>.
  #
  # == Cell inheritance
  #
  # Unlike controllers, Cells can form a class hierarchy.  When a cell class
  # is inherited by another cell class, its states are inherited as regular
  # methods are, but also its views are inherited.  Whenever a view is looked up,
  # the view finder first looks for a file in the directory belonging to the
  # current cell class, but if this is not found in the application or any
  # engine, the superclass' directory is checked.  This continues all the
  # way up until it stops at Cell::Base.
  #
  # For instance, when you have two cells:
  #   class MenuCell < Cell::Base
  #     def show
  #     end
  #
  #     def edit
  #     end
  #   end
  #
  #   class MainMenuCell < MenuCell
  #     .. # no need to redefine show/edit if they do the same!
  #   end
  # and the following directory structure in <tt>app/cells</tt>:
  #   app/cells/
  #     menu/
  #       show.html.erb
  #       edit.html.erb
  #     main_menu/
  #       show.html.erb
  # then when you call
  #   render_cell :main_menu, :show
  # the main menu specific show.html.erb (<tt>app/cells/main_menu/show.html.erb</tt>)
  # is rendered, but when you call
  #   render_cell :main_menu, :edit
  # cells notices that the main menu does not have a specific view for the
  # <tt>edit</tt> state, so it will render the view for the parent class,
  # <tt>app/cells/menu/edit.html.erb</tt>
  #
  #
  # == Gettext support
  #
  # Cells support gettext, just name your views accordingly. It works exactly equivalent
  # to controller views.
  #
  #   cells/user/user_form.html.erb
  #   cells/user/user_form_de.html.erb
  #
  # If gettext is set to DE_de, the latter view will be chosen.
  class Base
    include ActionController::Helpers
    include ActionController::RequestForgeryProtection
    
    helper ApplicationHelper
    
    
    class << self
      attr_accessor :request_forgery_protection_token
      
      # A template file will be looked for in each view path. This is typically
      # just RAILS_ROOT/app/cells, but you might want to add e.g.
      # RAILS_ROOT/app/views.
      def add_view_path(path)
        self.view_paths << RAILS_ROOT + '/' + path
      end
      
      # Creates a cell instance of the class <tt>name</tt>Cell, passing through 
      # <tt>opts</tt>.
      def create_cell_for(controller, name, opts={})
        class_from_cell_name(name).new(controller, opts)
      end
      
      # Declare a controller method as a helper.  For example,
      #   helper_method :link_to
      #   def link_to(name, options) ... end
      # makes the link_to controller method available in the view.
      def helper_method(*methods)
        methods.flatten.each do |method|
          master_helper_module.module_eval <<-end_eval
            def #{method}(*args, &block)
              @cell.send(%(#{method}), *args, &block)
            end
          end_eval
        end
      end
      
      # Return the default view for the given state on this cell subclass.
      # This is a file with the name of the state under a directory with the
      # name of the cell followed by a template extension.
      def view_for_state(state)
        "#{cell_name}/#{state}"
      end
      
      # Find a possible template for a cell's current state.  It tries to find a
      # template file with the name of the state under a subdirectory
      # with the name of the cell under the <tt>app/cells</tt> directory.
      # If this file cannot be found, it will try to call this method on
      # the superclass.  This way you only have to write a state template
      # once when a more specific cell does not need to change anything in
      # that view.
      def find_class_view_for_state(state)
        return [view_for_state(state)] if superclass == Cell::Base
        
        superclass.find_class_view_for_state(state) << view_for_state(state)
      end
      
      # Get the name of this cell's class as an underscored string,
      # with _cell removed.
      #
      # Example:
      #  UserCell.cell_name
      #  => "user"
      def cell_name
        name.underscore.sub(/_cell/, '')
      end
  
      # Given a cell name, finds the class that belongs to it.
      #
      # Example:
      # Cell::Base.class_from_cell_name(:user)
      # => UserCell
      def class_from_cell_name(cell_name)
        "#{cell_name}_cell".classify.constantize
      end
      
      def state2view_cache
        @state2view_cache ||= {}
      end
      
      def cache_configured?; ::ActionController::Base.cache_configured?; end
    end
    
    class_inheritable_array :view_paths, :instance_writer => false
    self.view_paths = ActionView::PathSet.new
    
    class_inheritable_accessor :allow_forgery_protection
    self.allow_forgery_protection = true
    
    class_inheritable_accessor :default_template_format
    self.default_template_format = :html
    
    
    delegate :params, :session, :request, :logger, :to => :controller
    
    
    attr_accessor :controller
    attr_reader   :state_name
    
    
    def initialize(controller, options={})
      @controller = controller
      @opts       = options
    end
    
    def cell_name
      self.class.cell_name
    end


    # Render the given state.  You can pass the name as either a symbol or
    # a string.
    def render_state(state)
      content = dispatch_state(state)
      
      return content if content.kind_of? String
      
      
      ### DISCUSS: are these vars really needed in state views?
      @cell       = self
      @state_name = state
      
      render_view_for(content, state)
    end
    
    # Call the state method.
    def dispatch_state(state)
      send(state)
    end
    
    # Render the view for the current state. Usually called at the end of a state method.
    #
    # ==== Options
    # * <tt>:view</tt> - Specifies the name of the view file to render. Defaults to the current state name.
    # * <tt>:template_format</tt> - Allows using a format different to <tt>:html</tt>.
    # * <tt>:layout</tt> - If set to a valid filename inside your cell's view_paths, the current state view will be rendered inside the layout (as known from controller actions). Layouts should reside in <tt>app/cells/layouts</tt>.
    #
    # Example:
    #  class MyCell < Cell::Base
    #    def my_first_state
    #      # ... do something
    #      render 
    #    end
    #
    # will just render the view <tt>my_first_state.html</tt>.
    # 
    #    def my_first_state
    #      # ... do something
    #      render :view => :my_first_state, :layout => "metal"
    #    end
    #
    # will also use the view <tt>my_first_state.html</tt> as template and even put it in the layout
    # <tt>metal</tt> that's located at <tt>$RAILS_ROOT/app/cells/layouts/metal.html.erb</tt>.
    def render(opts={})
      opts
    end
    
    # Render the view belonging to the given state. Will raise ActionView::MissingTemplate
    # if it can not find one of the requested view template. Note that this behaviour was
    # introduced in cells 2.3 and replaces the former warning message.
    def render_view_for(opts, state)
      view_class  = Class.new(Cell::View)
      action_view = view_class.new(self.class.view_paths, {}, @controller)
      action_view.cell = self
      
      # make helpers available:
      include_helpers_in_class(view_class)   
      
      # handle :layout, :template_format, :view
      render_opts = defaultize_render_options_for(opts, state)
      
      action_view.assigns         = assigns_for_view  # make instance vars available.
      action_view.template_format = render_opts[:template_format]
      
      template = find_family_view_for_state_with_caching(render_opts[:view], action_view)
      ### TODO: cache family_view for this cell_name/state in production mode,
      ###   so we can save the call to possible_paths_for_state.
      render_opts[:file] = template unless render_opts[:file]
      
      action_view.render(render_opts)      
    end
    
    # Defaultize the passed options from #render.
    def defaultize_render_options_for(opts, state)
      opts ||= {}
      opts[:template_format]  ||= self.class.default_template_format
      opts[:view]             ||= state
      opts
    end
    
    # Climbs up the inheritance hierarchy of the Cell, looking for a view 
    # for the current <tt>state</tt> in each level.
    # As soon as a view file is found it is returned as an ActionView::Template 
    # instance.
    ### DISCUSS: moved to Cell::View#find_template in rainhead's fork:
    def find_family_view_for_state(state, action_view)
      missing_template_exception = nil
      
      possible_paths_for_state(state).each do |template_path|
        # we need to catch MissingTemplate, since we want to try for all possible
        # family views.
        begin
          if view = action_view.try_picking_template_for_path(template_path)
            return view
          end
        rescue ::ActionView::MissingTemplate => missing_template_exception
        end
      end
      
      raise missing_template_exception
    end
    
    # In production mode, the view for a state/template_format is cached.
    ### DISCUSS: ActionView::Base already caches results for #pick_template, so maybe
    ### we should just cache the family path for a state/format?
    def find_family_view_for_state_with_caching(state, action_view)
      return find_family_view_for_state(state, action_view) unless self.class.cache_configured?
      
      # in production mode:
      key         = "#{state}/#{action_view.template_format}"
      state2view  = self.class.state2view_cache
      state2view[key] || state2view[key] = find_family_view_for_state(state, action_view)
    end
    
    # Find possible files that belong to the state.  This first tries the cell's
    # <tt>#view_for_state</tt> method and if that returns a true value, it
    # will accept that value as a string and interpret it as a pathname for
    # the view file. If it returns a falsy value, it will call the Cell's class
    # method find_class_view_for_state to determine the file to check.
    #
    # You can override the Cell::Base#view_for_state method for a particular
    # cell if you wish to make it decide dynamically what file to render.
    def possible_paths_for_state(state)
      self.class.find_class_view_for_state(state).reverse!
    end
    
    # Prepares the hash {instance_var => value, ...} that should be available
    # in the ActionView when rendering the state view.
    def assigns_for_view
      assigns = {}
      (self.instance_variables - ivars_to_ignore).each do |k|
       assigns[k[1..-1]] = instance_variable_get(k)
      end
      assigns
    end    
    
    
    # When passed a copy of the ActionView::Base class, it
    # will mix in all helper classes for this cell in that class.
    def include_helpers_in_class(view_klass)
      view_klass.send(:include, self.class.master_helper_module)
    end
    

    # Defines the instance variables that should <em>not</em> be copied to the 
    # View instance.
    def ivars_to_ignore;  ['@controller']; end
    
  end
end
