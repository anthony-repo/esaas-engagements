class AppeditrequestsController < ApplicationController
  before_action :auth_user?

  def index
    respond_to do |format|
      format.json { render :json => AppEditRequest.featured }
      format.html
    end
  end

  def show
    @edit_request = AppEditRequest.find(params[:id])
    @app = App.find(@edit_request.app_id)
    @description_updated = @edit_request.description != @app.description
    @features_updated = @edit_request.features != @app.features
  end

  def update
    edit_request = AppEditRequest.find(params[:id])
    app = App.find(edit_request.app_id)
    unless params[:feedback_given]
      app.description = edit_request.description
      app.features = edit_request.features
      app.save!
      edit_request.destroy
      redirect_to appeditrequests_path, alert: "Changes approved for #{app.name}"
    else
      new_request = edit_request.dup
      new_request.feedback = params[:feedback]
      new_request.status = :reviewed
      edit_request.destroy
      new_request.save
      redirect_to appeditrequests_path, alert: "Feedback submitted for #{app.name}"
    end
  end

  def auth_user?
    User.find_by_id(session[:user_id])&.coach?
  end
  
  def dumb
    return 0
  end
end
