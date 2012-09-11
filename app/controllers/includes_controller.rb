class IncludesController < ApplicationController
  load_and_authorize_resource
  
  def create
    @profile = Profile.accessible_by(current_ability).find(params[:profile_id])
    @include = @profile.includes.create(params[:include])
    
    respond_to do |format|
      if @include.save
        flash[:notice] = 'Include was successfully added.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @include, :status => :created, :location => @profile }
      else
        flash[:error] = 'Include was not valid.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @include.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @profile = Profile.accessible_by(current_ability).find(params[:profile_id])
    @include = @profile.includes.find(params[:id])
  end
  
  def update
    @profile = Profile.accessible_by(current_ability).find(params[:profile_id])
    @include = @profile.includes.find(params[:id])

    respond_to do |format|
      if @include.update_attributes(params[:include])
        flash[:notice] = 'Include was successfully updated.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Include was not valid.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @include.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @profile = Profile.accessible_by(current_ability).find(params[:profile_id])
    @include = @profile.includes.find(params[:id])
    @include.destroy

    respond_to do |format|
      format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
      format.xml  { head :ok }
    end
  end
end
