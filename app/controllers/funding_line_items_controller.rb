class FundingLineItemsController < OrganizationAwareController 

  # Include the fiscal year mixin
  include FiscalYear

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Funds", :funding_sources_path
  
  before_filter :check_for_cancel,        :only => [:create, :update]
  before_action :set_funding_line_item,   :only => [:show, :edit, :update, :destroy]
  
  INDEX_KEY_LIST_VAR    = "funding_line_item_key_list_cache_var"
  
  # GET /funding_line_items
  # GET /funding_line_items.json
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
    query = FundingLineItem.where(conditions.join(' AND '), *values).order('funding_source_id, fy_year')

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
        
    @funding_line_items = query  
    
    # cache the set of object keys in case we need them later
    cache_list(@funding_line_items, INDEX_KEY_LIST_VAR)
      
    if @funding_source_id.blank?
      add_breadcrumb "All"
    else 
      add_breadcrumb FundingSource.find(@funding_source_id)
    end
    add_breadcrumb "Appropriations"

    unless params[:format] == 'xls'
      # cache the set of object keys in case we need them later
      cache_list(@projects, INDEX_KEY_LIST_VAR)
        
      # generate the chart data
      @report = Report.find_by_class_name('CashFlowForecast')
      report_instance = @report.class_name.constantize.new
      @data = report_instance.get_data_from_result_list(@funding_line_items)      
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @funding_line_items }
      format.xls
    end
    
  end

  # GET /funding_line_items/1
  # GET /funding_line_items/1.json
  def show
    
    add_breadcrumb @funding_line_item.funding_source.funding_source_type, funding_sources_path(:funding_source_type_id => @funding_line_item.funding_source.funding_source_type)
    add_breadcrumb @funding_line_item.funding_source, funding_source_path(@funding_line_item.funding_source)
    add_breadcrumb @funding_line_item.name, funding_line_item_path(@funding_line_item)
    
    # get the @prev_record_path and @next_record_path view vars
    get_next_and_prev_object_keys(@funding_source, INDEX_KEY_LIST_VAR)
    @prev_record_path = @prev_record_key.nil? ? "#" : funding_line_item_path(@prev_record_key)
    @next_record_path = @next_record_key.nil? ? "#" : funding_line_item_path(@next_record_key)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @funding_line_item }
    end

  end
  
  # GET /funding_line_items/new
  def new

    @funding_source = FundingSource.find(params[:funding_source_id])
    @fiscal_years = get_fiscal_years
    
    add_breadcrumb @funding_source.funding_source_type, funding_sources_path(:funding_source_type_id => @funding_source.funding_source_type)
    add_breadcrumb "New Funding Line Item", new_funding_line_item_path

    @funding_line_item = FundingLineItem.new
    @funding_line_item.funding_source = @funding_source
    unless @funding_source.federal?
      @funding_line_item.funding_line_item_type = FundingLineItemType.find_by_code('OT') 
    end
    
  end

  # GET /funding_line_items/1/edit
  def edit
    
    add_breadcrumb @funding_line_item.name, funding_line_item_path(@funding_line_item)
    add_breadcrumb "Modify"

  end

  # POST /funding_line_items
  # POST /funding_line_items.json
  def create
    

    @funding_line_item = FundingLineItem.new(form_params)
    @funding_line_item.organization = @organization
    @funding_line_item.creator = current_user
    @funding_line_item.updator = current_user

    @funding_source = @funding_line_item.funding_source
    @fiscal_years = get_fiscal_years
    
    add_breadcrumb @funding_source.funding_source_type, funding_sources_path(:funding_source_type_id => @funding_source.funding_source_type)
    add_breadcrumb "New Funding Line Item", new_funding_line_item_path
    
    respond_to do |format|
      if @funding_line_item.save        
        notify_user(:notice, "The Funding Line Item was successfully saved.")
        format.html { redirect_to funding_line_item_url(@funding_line_item) }
        format.json { render action: 'show', status: :created, location: @funding_line_item }
      else
        format.html { render action: 'new' }
        format.json { render json: @funding_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /funding_line_items/1
  # PATCH/PUT /funding_line_items/1.json
  def update

    add_breadcrumb @funding_line_item.name, funding_line_item_path(@funding_line_item)
    add_breadcrumb "Modify"

    @funding_line_item.updator = current_user

    respond_to do |format|
      if @funding_line_item.update(form_params)
        notify_user(:notice, "The Funding Line Item was successfully updated.")
        format.html { redirect_to funding_line_item_url(@funding_line_item) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @funding_line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /funding_sources/1
  # DELETE /funding_sources/1.json
  def destroy
    @funding_line_item.destroy
    notify_user(:notice, "The Funding Line Item was successfully removed.")
    respond_to do |format|
      format.html { redirect_to funding_line_items_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_funding_line_item
      @funding_line_item = FundingLineItem.find_by_object_key(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def form_params
      params.require(:funding_line_item).permit(funding_line_item_allowable_params)
    end

  def check_for_cancel
    unless params[:cancel].blank?
      # get the funding source, if one was being edited
      if params[:id]
        redirect_to(funding_line_item_url(@funding_line_item))
      else
        redirect_to(funding_line_items_url)
      end
    end
  end

end
