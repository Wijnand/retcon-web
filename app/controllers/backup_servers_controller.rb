class BackupServersController < ApplicationController
  filter_resource_access
  
  # GET /backup_servers
  # GET /backup_servers.xml
  def index
    @backup_servers = BackupServer.find(:all, :order => 'hostname', :include => [:user])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @backup_servers }
    end
  end

  # GET /backup_servers/1
  # GET /backup_servers/1.xml
  def show
    @backup_server = BackupServer.find(params[:id], :include => [:backup_jobs, :problems])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @backup_server }
    end
  end

  # GET /backup_servers/new
  # GET /backup_servers/new.xml
  def new
    @backup_server = BackupServer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @backup_server }
    end
  end

  # GET /backup_servers/1/edit
  def edit
    @backup_server = BackupServer.find(params[:id])
  end

  # POST /backup_servers
  # POST /backup_servers.xml
  def create
    @backup_server = BackupServer.new(params[:backup_server])

    respond_to do |format|
      if @backup_server.save
        flash[:notice] = 'Backup Server was successfully added.'
        format.html { redirect_to(@backup_server) }
        format.xml  { render :xml => @backup_server, :status => :created, :location => @backup_server }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @backup_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /backup_servers/1
  # PUT /backup_servers/1.xml
  def update
    @backup_server = BackupServer.find(params[:id])

    respond_to do |format|
      if @backup_server.update_attributes(params[:backup_server])
        flash[:notice] = 'Backup Server was successfully updated.'
        format.html { redirect_to(@backup_server) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @backup_server.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /backup_servers/1
  # DELETE /backup_servers/1.xml
  def destroy
    @backup_server = BackupServer.find(params[:id])
    @backup_server.destroy
    respond_to do |format|
      format.html { redirect_to(backup_servers_url) }
      format.xml  { head :ok }
    end
  end
end
