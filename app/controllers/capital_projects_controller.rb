class CapitalProjectsController < OrganizationAwareController
   
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path
  
  # Include the fiscal year mixin
  include FiscalYear
    
  #before_filter :authorize_admin
  before_filter :check_for_cancel,  :only =>    [:create, :update, :runner]
  before_filter :get_project,       :except =>  [:index, :create, :new, :runner, :builder]
  
  INDEX_KEY_LIST_VAR    = "capital_project_key_list_cache_var"
  SESSION_VIEW_TYPE_VAR = 'capital_projects_subnav_view_type'
    
  def builder

    add_breadcrumb "Capital Needs SOGR Builder", builder_capital_projects_path   
    
    @builder_proxy = BuilderProxy.new
    @message = "Creating SOGR projects. This process might take a while."
    
  end
  
  def runner

    add_breadcrumb "Capital Needs SOGR Builder", builder_capital_projects_path   

    @builder_proxy = BuilderProxy.new(params[:builder_proxy])
    if @builder_proxy.valid?
      # Sleep for a couple of seconds so that the screen can display the waiting 
      # message and the user can read it.
      sleep 2
      
      # Run the builder
      options = {}
      options[:asset_type_ids] = @builder_proxy.asset_types
      
      #puts options.inspect
      builder = CapitalProjectBuilder.new
      num_created = builder.build(@organization, options)
  
      # Let the user know the results
      if num_created > 0
        msg = "Capital Project Builder completed. #{num_created} projects were added to your capital needs list."
        notify_user(:notice, msg)
        # Add a row into the activity table
        ActivityLog.create({:organization_id => @organization.id, :user_id => current_user.id, :item_type => "CapitalProjectBuilder", :activity => msg, :activity_time => Time.now})
      else
        notify_user(:notice, "No projects were created.")
      end
      redirect_to capital_projects_url
      return      
    else
      respond_to do |format|
        format.html { render :action => "builder" }
      end
    end
    
  end
  
  def index

    @fiscal_years = get_fiscal_years
   
     # Start to set up the query
    conditions  = []
    values      = []
        
    # Check to see if we got an organization to sub select on. 
    @org_filter = params[:org_id]
    conditions << 'organization_id IN (?)'
    if @org_filter.blank?
      values << @organization_list      
    else
      @org_filter = @org_filter.to_i
      values << [@org_filter]
    end

    # See if we got search
    @fiscal_year = params[:fiscal_year]
    unless @fiscal_year.blank?
      @fiscal_year = @fiscal_year.to_i
      conditions << 'fy_year = ?'
      values << @fiscal_year
    end

    @capital_project_type_id = params[:capital_project_type_id]
    unless @capital_project_type_id.blank?
      @capital_project_type_id = @capital_project_type_id.to_i
      if @capital_project_type_id > 0
        conditions << 'capital_project_type_id = ?'
        values << @capital_project_type_id
      end
    end

    @capital_project_status_type_id = params[:capital_project_status_type_id]
    unless @capital_project_status_type_id.blank?
      @capital_project_status_type_id = @capital_project_status_type_id.to_i
      if @capital_project_status_type_id > 0
        conditions << 'capital_project_status_type_id = ?'
        values << @capital_project_status_type_id
      end
    end
    
    # Get the capital project status type filter, if one is not found default to 0 
    @capital_project_type_id = params[:capital_project_type_id]
    if @capital_project_type_id.blank?
      @capital_project_type_id = 0
    else
      @capital_project_type_id = @capital_project_type_id.to_i
    end
    
    # Filter by funding source and/or asset type. This takes more work and each uses a custom query to pre-select
    # capital projects that meet this partial match
    
    # Funding Source. Requires joining across CP <- ALI <- FR <- FA <- FS
    @funding_source_id = params[:funding_source_id]
    unless @funding_source_id.blank?
      funding_source = FundingSource.find(@funding_source_id)
      @funding_source_id = funding_source.id
      column_name = funding_source.federal? ? 'federal_funding_line_item_id' : 'state_funding_line_item_id'
      if @funding_source_id > 0
        capital_project_ids = []
        # Use a custom query to join across the five tables
        query = "SELECT DISTINCT(id) FROM capital_projects WHERE id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE id IN (SELECT activity_line_item_id FROM funding_requests WHERE #{column_name} IN (SELECT id FROM funding_line_items WHERE funding_source_id = #{@funding_source_id})))"
        cps = CapitalProject.connection.execute(query, :skip_logging)
        cps.each do |cp|
          capital_project_ids << cp[0]
        end
        conditions << 'id IN (?)'
        values << capital_project_ids.uniq  # make sure there are no duplicates
      end
    end

    # Filter by asset type. Requires jopining across CP <- ALI <- ALI-Assets <- Assets
    @asset_subtype_id = params[:asset_subtype_id]
    unless @asset_subtype_id.blank?
      @asset_subtype_id = @asset_subtype_id.to_i
      if @asset_subtype_id > 0
        capital_project_ids = []
        # first get a list of matching asset ids for the selected organizations. This is better as a ruby query
        asset_ids = Asset.where('asset_subtype_id = ? AND organization_id IN (?)', @asset_subtype_id, values[0]).pluck(:id)
        unless asset_ids.empty?
          # now get CPs by subselecting on CP <- ALI <- ALI-Assets        
          query = "SELECT DISTINCT(id) FROM capital_projects WHERE id IN (SELECT DISTINCT(capital_project_id) FROM activity_line_items WHERE id IN (SELECT DISTINCT(activity_line_item_id) FROM activity_line_items_assets WHERE asset_id IN (#{asset_ids.join(',')})))"
          cps = CapitalProject.connection.execute(query, :skip_logging)
          cps.each do |cp|
            capital_project_ids << cp[0]
          end
        end
        conditions << 'id IN (?)'
        values << capital_project_ids.uniq  # make sure there are no duplicates
      end
    end
            
    #puts conditions.inspect
    #puts values.inspect
    
    # Get the initial list of capital projects. These might need to be filtered further if the user specified a funding source filter
    @projects = CapitalProject.where(conditions.join(' AND '), *values).order(:fy_year, :capital_project_type_id, :created_at)
    
    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@projects, INDEX_KEY_LIST_VAR)
        
      # generate the chart data
      @report = Report.find_by_class_name('CapitalNeedsForecast')
      report_instance = @report.class_name.constantize.new
      @data = report_instance.get_data_from_result_list(@projects)      
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @projects }
      format.xls
    end
  end

  def show

    add_breadcrumb @project.project_number, capital_project_path(@project)    

    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@project, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : capital_project_path(@prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : capital_project_path(@next_record_key)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @project }
    end
  end

  
  def new

    add_breadcrumb "New", new_capital_project_path    
    
    @project = CapitalProject.new
    
    @fiscal_years = get_fiscal_years
    
  end

  # Move a project forward or backward by the specified number of years.
  def shift_fiscal_year
    num_years = params[:num_years].to_i
    new_project_year = @project.fy_year + num_years
    
    # get the last year that a project can be scheduled
    last_year = last_fiscal_year_year
    
    # Check to see if they are attempting to move the project earlier than the current fiscal year
    if new_project_year < current_fiscal_year_year
      notify_user(:alert, "Project #{@project.project_number} can't be scheduled earlier than #{current_fiscal_year}.")
    elsif new_project_year > last_year
      notify_user(:alert, "Project #{@project.project_number} can't be scheduled later than #{last_year}.")      
    else
      # Create a transaction to manage all the updates
      CapitalProject.transaction do    
        
        # Update the fiscal year for the project. This also creates a new project number      
        original_fiscal_year = @project.fy_year
        @project.fy_year = new_project_year
        @project.update_project_number
        @project.save
        # Update the ALI assets and set the scheduled replacement date to the date
        @project.activity_line_items.each do |ali|
          ali.assets.each do |a|
            if [1].include? @project.capital_project_type.id
              # SOGR replacement projects. Check to make sure that these are not replacements of replacments. If they are
              # the fiscal year for the asset will be different from the fiscal year for the project
              unless a.scheduled_replacement_year == original_fiscal_year
                a.scheduled_replacement_year = @project.fy_year 
                a.scheduled_by_user = true
                a.save
              end
            elsif [2,3].include?  @project.capital_project_type.id
              # SOGR rehabilitation or rail mid-year rebuild
              a.scheduled_rehabilitation_year = @project.fy_year
              a.save
            end
          end
          # close out the transaction
        end
      end                
      notify_user(:notice, "The project was re-scheduled for #{@project.fy_year}. The new project number is #{@project.project_number}.")
    end
    
    # display the previous view
    redirect_to :back
  end
  
  def edit

    add_breadcrumb @project.project_number, capital_project_path(@project)    
    add_breadcrumb "Modify", edit_capital_project_path(@project)    
    
    @fiscal_years = get_fiscal_years
    
  end
  
  def copy
    
    new_project = @project.dup
    new_project.save
    @project.activity_line_items.each do |ali|
      new_ali = ali.dup
      new_project.activity_line_items << new_ali
    end
    
    notify_user(:notice, "Capital Project #{@project.project_number} was successfully copied to #{new_project.project_number}.")
    redirect_to capital_project_url(new_project)

  end
  
  def create

    add_breadcrumb "New", new_capital_project_path    

    @project = CapitalProject.new(form_params)
    @project.organization = @organization
    @fiscal_years = get_fiscal_years

    respond_to do |format|
      if @project.save
        notify_user(:notice, "Capital Project #{@project.project_number} was successfully created.")
        format.html { redirect_to capital_project_url(@project) }
        format.json { render :json => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    add_breadcrumb @project.project_number, capital_project_path(@project)    
    add_breadcrumb "Modify", edit_capital_project_path(@project)    
    @fiscal_years = get_fiscal_years

    respond_to do |format|
      if @project.update_attributes(form_params)
        @project.update_project_number
        @project.save
        notify_user(:notice, "Capital Project #{@project.name} was successfully updated.")
        format.html { redirect_to capital_project_url(@project) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy

    @project.destroy
    notify_user(:notice, "Capital Project was successfully removed.")
    respond_to do |format|
      format.html { redirect_to capital_projects_url }
      format.json { head :no_content }
    end
  end
  
  protected
    
      
  private
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:capital_project).permit(capital_project_allowable_params)
  end

  def get_project
    # See if it is our project
    @project = CapitalProject.find_by_object_key(params[:id]) unless params[:id].nil?
    # if not found or the object does not belong to the users
    # send them back to index.html.erb
    if @project.nil?
      notify_user(:alert, 'Record not found!')
      redirect_to(capital_projects_url)
      return
    end
    
  end
  
  def check_for_cancel
    unless params[:cancel].blank?
      # get the policy, if one was being edited
      if params[:id]
        redirect_to(capital_project_url(params[:id]))
      else
        redirect_to(capital_projects_url)
      end
    end
  end
end
