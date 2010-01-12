class IncludesController < ApplicationController
  filter_resource_access
  
  def create
    @profile = Profile.find(params[:profile_id])
    @include = @profile.includes.create(params[:include])
    
    respond_to do |format|
      if @include.save
        flash[:notice] = 'Exclude was successfully added.'
        format.html { redirect_to(@profile) }
        format.xml  { render :xml => @include, :status => :created, :location => @profile }
      else
        flash[:error] = 'Exclude was not valid.'
        format.html { redirect_to @profile}
        format.xml  { render :xml => @include.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def edit
    @profile = Profile.find(params[:profile_id])
    @include = @profile.includes.find(params[:id])
  end
  
  def update
    @profile = Profile.find(params[:profile_id])
    @include = @profile.includes.find(params[:id])

    respond_to do |format|
      if @include.update_attributes(params[:include])
        flash[:notice] = 'Include was successfully updated.'
        format.html { redirect_to(@profile) }
        format.xml  { head :ok }
      else
        flash[:error] = 'Include was not valid.'
        format.html { redirect_to @profile}
        format.xml  { render :xml => @include.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @profile = Profile.find(params[:profile_id])
    @include = @profile.includes.find(params[:id])
    @include.destroy

    respond_to do |format|
      format.html { redirect_to(@profile) }
      format.xml  { head :ok }
    end
  end
end
