class CommandsController < ApplicationController
  filter_resource_access
  layout proc { |controller| controller.request.xhr? ? 'popup' : 'application' }
  # GET /commands
  # GET /commands.xml
  def index
    @commands = current_user.commands.all(:conditions => { :exitstatus => nil})

    respond_to do |format|
      format.xml  { render :xml => @commands }
    end
  end

  # GET /commands/1
  # GET /commands/1.xml
  def show
    @command = Command.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @command }
    end
  end

  # PUT /commands/1
  # PUT /commands/1.xml
  def update
    @command = Command.find(params[:id])

    respond_to do |format|
      if @command.update_attributes(params[:command])
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @command.errors, :status => :unprocessable_entity }
      end
    end
  end

end
