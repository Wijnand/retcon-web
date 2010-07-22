class ExcludesController < ApplicationController
  filter_resource_access
  
  def create
    @profile = Profile.find(params[:profile_id])
    @exclude = @profile.excludes.create(params[:exclude])
    
    respond_to do |format|
      if @exclude.save
        flash[:notice] = 'Exclude was successfully added.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @exclude, :status => :created, :location => @profile }
      else
        flash[:error] = 'Exclude was not valid.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @exclude.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @profile = Profile.find(params[:profile_id])
    @exclude = @profile.excludes.find(params[:id])
  end
  
  def update
    @profile = Profile.find(params[:profile_id])
    @exclude = @profile.excludes.find(params[:id])

    respond_to do |format|
      if @exclude.update_attributes(params[:exclude])
        flash[:notice] = 'Exclude was successfully updated.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Exclude was not valid.'
        format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
        format.xml  { render :xml => @exclude.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @profile = Profile.find(params[:profile_id])
    @exclude = @profile.excludes.find(params[:id])
    @exclude.destroy

    respond_to do |format|
      format.html { @profile.exclusive? ? redirect_to(@profile.servers[0]) : redirect_to(@profile) }
      format.xml  { head :ok }
    end
  end
end
