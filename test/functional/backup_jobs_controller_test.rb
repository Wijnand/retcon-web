require 'test_helper'

class BackupJobsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:backup_jobs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create backup_job" do
    assert_difference('BackupJob.count') do
      post :create, :backup_job => { }
    end

    assert_redirected_to backup_job_path(assigns(:backup_job))
  end

  test "should show backup_job" do
    get :show, :id => backup_jobs(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => backup_jobs(:one).to_param
    assert_response :success
  end

  test "should update backup_job" do
    put :update, :id => backup_jobs(:one).to_param, :backup_job => { }
    assert_redirected_to backup_job_path(assigns(:backup_job))
  end

  test "should destroy backup_job" do
    assert_difference('BackupJob.count', -1) do
      delete :destroy, :id => backup_jobs(:one).to_param
    end

    assert_redirected_to backup_jobs_path
  end
end
