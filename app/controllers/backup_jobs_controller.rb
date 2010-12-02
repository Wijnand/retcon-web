class BackupJobsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @backup_jobs = BackupJob.accessible_by(current_ability).queued
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @backup_jobs }
      format.json  { render :json => @backup_jobs }
    end
  end

  # GET /backup_jobs/1
  # GET /backup_jobs/1.xml
  def show
    @backup_job = BackupJob.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @backup_job }
    end
  end

  # POST /backup_jobs
  # POST /backup_jobs.xml
  def create
    @backup_job = BackupJob.accessible_by(current_ability).new(params[:backup_job])

    respond_to do |format|
      if @backup_job.save
        @backup_job.run if @backup_job.start_now
        flash[:notice] = 'BackupJob was successfully created.'
        format.html { redirect_to(@backup_job.server) }
        format.xml  { render :xml => @backup_job, :status => :created, :location => @backup_job }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @backup_job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /backup_jobs/1
  # PUT /backup_jobs/1.xml
  def update
    @backup_job = BackupJob.accessible_by(current_ability).find(params[:id])

    respond_to do |format|
      if @backup_job.update_attributes(params[:backup_job])
        flash[:notice] = 'BackupJob was successfully updated.'
        format.html { redirect_to(@backup_job) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @backup_job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /backup_jobs/1
  # DELETE /backup_jobs/1.xml
  def destroy
    @backup_job = BackupJob.accessible_by(current_ability).find(params[:id])
    @backup_job.destroy

    respond_to do |format|
      format.html { redirect_to(backup_jobs_url) }
      format.xml  { head :ok }
    end
  end

  def redo_last
    @backup_job = BackupJob.accessible_by(current_ability).find(params[:id])
    if command = @backup_job.commands.last
      command.destroy
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.xml  { head :ok }
    end
  end
end
