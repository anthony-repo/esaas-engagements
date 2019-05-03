class AppsController < ApplicationController
  before_action :set_app, only: [:show, :edit, :update, :destroy]
  skip_before_filter :logged_in?, :only => :index
  skip_before_filter :auth_user?, :only => :index

  # GET /apps
  # GET /apps.json
  def index
    deploy_vet_map
    @total_app = @total_deploy + @total_vet
    @current_user = User.find_by_id(session[:user_id])
    
    @page_dict = {"10" => 10, "50" => 50, "100" => 100, "All" => @total_app}
    session[:app_page_num] ||= '1'
    session[:app_each_page] = params[:app_each_page] || session[:app_each_page] || '10' 
    session[:app_page_num] = '1'if params[:app_each_page]
    @each_page = @page_dict[session[:app_each_page]].to_i
    change_page_num
    
    @apps = App.limit(@each_page).offset(@each_page*(@page_num-1))
    respond_to do |format|
      format.json { render :json => @apps.featured }
      format.html
    end
  end

  # GET /apps/1
  # GET /apps/1.json
  def show
  end

  # GET /apps/new
  def new
    if User.find_by_id(session[:user_id]).coach?
      @app = App.new
    else
      redirect_to apps_path, alert: 'Error: Only Staff can create an app'
    end
  end

  # GET /apps/1/edit
  def edit
    if User.find_by_id(session[:user_id]).coach?
      @comments = App.find_by_id(params[:id]).comments
    else
      redirect_to apps_path, alert: 'Error: Only Staff can edit an app'
    end
  end

  # POST /apps
  # POST /apps.json
  def create
    @app = App.new(app_params)

    respond_to do |format|
      if @app.save
        format.html { redirect_to apps_path, notice: 'App was successfully created.' }
        format.json { render :show, status: :created, location: @app }
      else
        format.html { render :new }
        format.json { render json: @app.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /apps/1
  # PATCH/PUT /apps/1.json
  def update
    respond_to do |format|
      if @app.update(app_params)
        format.html { redirect_to apps_path, notice: 'App was successfully updated.' }
        format.json { render :show, status: :ok, location: @app }
      else
        format.html { render :action => :edit }
        format.json { render json: @app.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /apps/1
  # DELETE /apps/1.json
  def destroy
    if User.find_by_id(session[:user_id]).coach?
      @app.destroy
      respond_to do |format|
        format.html { redirect_to apps_url, notice: 'App was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      redirect_to apps_path, alert: 'Error: Only Staff can destroy an app'
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_app
      @app = App.find(params[:id])
      @engagements = @app.engagements
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def app_params
      params.require(:app).permit(:name, :description, :deployment_url, :repository_url, :code_climate_url, :org_id, :status, :comments)
    end

    # count the number of apps for each status and
    # the total number of apps for each category
    def deploy_vet_map
      status_map =  App.group(:status).reorder(:status).count # should be in model?
      @deployment_map = {}
      @vetting_map = {}
      @total_deploy = 0
      @total_vet = 0
      status_map.each do |status, count|
        if App.getAllVettingStatuses.include? status then
          @vetting_map[App.statuses.keys[status]] = count
          @total_vet += count
        else
          @deployment_map[App.statuses.keys[status]] = count
          @total_deploy += count
        end
      end
    end

    # Give react to the page change requests
    def change_page_num
      page_num = (params[:prev] || session[:app_page_num]).to_i
      max_page_num =  (@total_app - 1) / @each_page + 1
      @page_num = {"Previous"=>page_num-1,"Next"=>page_num+1,"First"=>1,"Last"=>max_page_num, nil => page_num}[params[:app_page_action]].to_i
      flash.now[:alert] = "You are already on the FIRST page." if @page_num == 0
      flash.now[:alert] = "You are already on the LAST page." if @page_num == max_page_num + 1
      @page_num = [[1,@page_num].max,max_page_num].min	
      session[:app_page_num] = @page_num.to_s
    end
end
