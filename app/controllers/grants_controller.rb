class GrantsController < OrganizationAwareController 

  # Include the fiscal year mixin
  include FiscalYear

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Funds", :grants_path
  
  before_action :set_grant,   :only => [:show, :edit, :update, :destroy]
  
  INDEX_KEY_LIST_VAR    = "grants_key_list_cache_var"
  
  # GET /grants
  # GET /grants.json
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
        
    @funding_source_id = params[:funding_source_id]
    unless @funding_source_id.blank?
      @funding_source_id = @funding_source_id.to_i
      conditions << 'funding_source_id = ?'
      values << @funding_source_id
    end

    #puts conditions.inspect
    #puts values.inspect
    query = Grant.where(conditions.join(' AND '), *values).order('fy_year, funding_source_id')

    # Check for joined queries
    @funding_source_type_id = params[:funding_source_type_id]
    unless @funding_source_type_id.blank?
      @funding_source_type_id = @funding_source_type_id.to_i
      query = query.joins(:funding_source).where('funding_sources.funding_source_type_id = ?', @funding_source_type_id)
    end

    # Check for joined queries
    @discretionary_type_id = params[:discretionary_type_id]
    unless @discretionary_type_id.blank?
      @discretionary_type_id = @discretionary_type_id.to_i
      query = query.joins(:funding_source).where('funding_sources.discretionary_fund = ?', @discretionary_type_id)
    end
        
    @grants = query  
    
      
    if @funding_source_id.blank?
      add_breadcrumb "All"
    else 
      add_breadcrumb FundingSource.find(@funding_source_id)
    end
    add_breadcrumb "Grants"

    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@grants, INDEX_KEY_LIST_VAR)
        
      # generate the chart data
      @report = Report.find_by_class_name('CashFlowForecast')
      report_instance = @report.class_name.constantize.new
      @data = report_instance.get_data_from_result_list(@grants)      
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @grants }
      format.xls
    end
    
  end

  # GET /grants/1
  # GET /grants/1.json
  def show
    
    add_breadcrumb @grant.funding_source.funding_source_type, funding_sources_path(:funding_source_type_id => @grant.funding_source.funding_source_type)
    add_breadcrumb @grant.funding_source, funding_source_path(@grant.funding_source)
    add_breadcrumb @grant.name, funding_line_item_path(@grant)
    
    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@grant, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : grant_path(@prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : grant_path(@next_record_key)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @grant }
    end

  end
  
  # GET /grant/new
  def new

    @grant = Grant.find(params[:grant_id])
    @fiscal_years = get_fiscal_years
    
    add_breadcrumb @grant.funding_source_type, grants_path(:funding_source_type_id => @grant.funding_source_type)
    add_breadcrumb "New Grant", new_grant_path

    @grant = Grant.new
    @grant.funding_source = @funding_source
    
  end

  # GET /grants/1/edit
  def edit
    
    add_breadcrumb @grant.name, grant_path(@grant)
    add_breadcrumb "Modify"
    @fiscal_years = get_fiscal_years

  end

  # POST /grants
  # POST /grants.json
  def create
    

    @grant = Grant.new(form_params)
    @grant.organization = @organization

    @funding_source = @grant.funding_source
    @fiscal_years = get_fiscal_years
    
    add_breadcrumb @funding_source.funding_source_type, funding_sources_path(:funding_source_type_id => @grant.funding_source_type)
    add_breadcrumb "New Grant", new_grant_path
    
    respond_to do |format|
      if @grant.save        
        notify_user(:notice, "The Grant was successfully saved.")
        format.html { redirect_to grant_url(@grant) }
        format.json { render action: 'show', status: :created, location: @grant }
      else
        format.html { render action: 'new' }
        format.json { render json: @grant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /grants/1
  # PATCH/PUT /grants/1.json
  def update

    add_breadcrumb @grant.name, grant_path(@grant)
    add_breadcrumb "Modify"

    respond_to do |format|
      if @grant.update(form_params)
        notify_user(:notice, "The Gratn was successfully updated.")
        format.html { redirect_to grant_url(@grant) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @grant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /grants/1
  # DELETE /grants/1.json
  def destroy
    @grant.destroy
    notify_user(:notice, "The Grant was successfully removed.")
    respond_to do |format|
      format.html { redirect_to grants_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_grant
      @grant = Grant.find_by_object_key(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def form_params
      params.require(:grant).permit(Grant.allowable_params)
    end

end
