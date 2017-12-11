class UserActivityLineItemFiltersController < OrganizationAwareController

  add_breadcrumb "Home",  :root_path

  before_action :set_user_activity_line_item_filter, :only => [:show, :edit, :update, :destroy]

  # GET /user_activity_line_item_filters
  # GET /user_activity_line_item_filters.json
  def index

    add_breadcrumb "ALI Filters"

    @user_activity_line_item_filters = current_user.user_activity_line_item_filters

  end

  # GET /user_activity_line_item_filters/1
  # GET /user_activity_line_item_filters/1.json
  def show

    add_breadcrumb "ALI Filters", user_user_activity_line_item_filters_path(current_user)
    add_breadcrumb @user_activity_line_item_filter.name

  end

  #
  def use
    # Set the user's organization list for reporting and filtering to the list defined by
    # the selected filter

    @user_activity_line_item_filter = UserActivityLineItemFilter.find_by_object_key(params[:user_activity_line_item_filter_id])

    if @user_activity_line_item_filter.nil?
      notify_user(:alert, 'Record not found!')

      redirect_to :back
      return
    end

    set_current_user_activity_line_item_filter



    # possibly improve later on. right now handle on a case by case basis
    old_path = URI(request.referer)
    recognized_path = Rails.application.routes.recognize_path(old_path.path)
    # if currently on a filter detail page direct to detail page of filter just set
    if recognized_path[:action] == "show" && recognized_path[:controller] == "user_activity_line_item_filters"
      redirect_to user_user_activity_line_item_filter_path(current_user, @user_activity_line_item_filter)
    elsif recognized_path[:action] == "show" && (["capital_projects", "activity_line_items"].include? recognized_path[:controller])
      redirect_to capital_projects_path
    else
      old_path.query = Rack::Utils.parse_nested_query(old_path.query).
          # referrer_url.query returns the existing query string => "f=b"
          # Rack::Utils.parse_nested_query converts query string to hash => {f: "b"}
          except('ali').
          # merge appends or overwrites the new parameter  => {f: "b", cp: :foo'}
          to_query
      redirect_to old_path.to_s
    end

  end

  # GET /user_activity_line_item_filters/new
  def new

    add_breadcrumb "ALI Filters", user_user_activity_line_item_filters_path(current_user)
    add_breadcrumb "New"

    @user_activity_line_item_filter = UserActivityLineItemFilter.new
  end

  # GET /user_activity_line_item_filters/1/edit
  def edit

    add_breadcrumb "ALI Filters", user_user_activity_line_item_filters_path(current_user)
    add_breadcrumb @user_activity_line_item_filter.name, user_user_activity_line_item_filter_path(current_user, @user_activity_line_item_filter)
    add_breadcrumb "Update"


  end

  # POST /user_activity_line_item_filters
  # POST /user_activity_line_item_filters.json
  def create

    add_breadcrumb "ALI Filters", user_user_activity_line_item_filters_path(current_user)
    add_breadcrumb "New"

    @user_activity_line_item_filter = UserActivityLineItemFilter.new(form_params)
    @user_activity_line_item_filter.creator = current_user
    if params[:share_filter] == 'all_orgs'
      users = []
      current_user.user_organization_filters.system_filters.first.get_organizations.each do |org|
        users << org.users
      end
      @user_activity_line_item_filter.users = users.flatten.uniq
      @user_activity_line_item_filter.resource = nil
    elsif params[:share_filter] == 'main_org'
      @user_activity_line_item_filter.users = current_user.organization.users
      @user_activity_line_item_filter.resource = current_user.organization
    else
      @user_activity_line_item_filter.users = [current_user]
      @user_activity_line_item_filter.resource = nil
    end

    respond_to do |format|
      if @user_activity_line_item_filter.save

        if params[:commit] == "Update and Select This Filter"
          set_current_user_activity_line_item_filter
        end

        notify_user(:notice, 'Filter was successfully created.')
        format.html { redirect_to [current_user, @user_activity_line_item_filter] }
        format.json { render action: 'show', status: :created, location: @user_activity_line_item_filter }
      else
        format.html { render action: 'new' }
        format.json { render json: @user_activity_line_item_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /user_activity_line_item_filters/1
  # PATCH/PUT /user_activity_line_item_filters/1.json
  def update

    respond_to do |format|
      if @user_activity_line_item_filter.update(form_params)

        if params[:share_filter] == 'all_orgs'
          users = []
          current_user.user_organization_filters.system_filters.first.get_organizations.each do |org|
            users << org.users
          end
          @user_activity_line_item_filter.users = users.flatten.uniq
          @user_activity_line_item_filter.resource = nil
        elsif params[:share_filter] == 'main_org'
          @user_activity_line_item_filter.users = current_user.organization.users
          @user_activity_line_item_filter.resource = current_user.organization
        else
          @user_activity_line_item_filter.users = [current_user]
          @user_activity_line_item_filter.resource = nil
        end


        if params[:commit] == "Update and Select This Filter"
          set_current_user_activity_line_item_filter

          # if not managing filters go to last page
          unless URI(request.referer).path =~ /\/users\/[[:alnum:]]{12}\/user_activity_line_item_filters\/[[:alnum:]]{12}/
            redirect_to_back = true
          end
        end


        notify_user(:notice, 'Filter was successfully updated.')
        format.html {
          if redirect_to_back
            redirect_to :back
          else
            redirect_to [current_user, @user_activity_line_item_filter]
          end
        }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user_activity_line_item_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_activity_line_item_filters/1
  # DELETE /user_activity_line_item_filters/1.json
  def destroy
    @user_activity_line_item_filter.destroy
    notify_user(:notice, 'Filter was successfully removed.')
    respond_to do |format|
      format.html { redirect_to user_user_activity_line_item_filters_path(current_user) }
      format.json { head :no_content }
    end
  end

  private

  def set_current_user_activity_line_item_filter
    Rails.logger.debug "Setting agency filter to: #{@user_activity_line_item_filter}"

    # Save the selection. Next time the user logs in the filter will be reset
    current_user.update(user_activity_line_item_filter: @user_activity_line_item_filter)

    session[:user_activity_line_item_filter] = @user_activity_line_item_filter.name
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user_activity_line_item_filter
    @user_activity_line_item_filter = UserActivityLineItemFilter.find_by_object_key(params[:id])

    if @user_activity_line_item_filter.nil?
      redirect_to '/404'
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:user_activity_line_item_filter).permit(user_activity_line_item_filter_params)
  end
end
