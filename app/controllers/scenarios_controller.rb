#-------------------------------------------------------------------------------
# ScenariosController
#
# Basic Scenario CRUD management
#
#-------------------------------------------------------------------------------
class ScenariosController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scenarios", :scenarios_path

  # Include the fiscal year mixin
  include FiscalYear

  include TransamFormatHelper

  #-----------------------------------------------------------------------------
  # 
  #-----------------------------------------------------------------------------
  def index
    @scenarios = Scenario.all 

    respond_to do |format|
      format.html
    end

  end

  #-----------------------------------------------------------------------------
  # Show
  #-----------------------------------------------------------------------------
  def show
    set_scenario
    add_breadcrumb "#{@scenario.name}"

    @transit_assets = TransitAsset.where(organization: @scenario.organization)
    if params[:filter_year]
      @phase_filter_year = params[:filter_year] # from url
    elsif @scenario.draft_project_phases.length > 0
      @phase_filter_year = @scenario.draft_project_phases.min_by(&:fy_year).fy_year.to_s # default to earliest fy year
    else
      @phase_filter_year = Date.new.year # default to 'now' if no phases
    end
    #@phase_filter_ali_code = params[:filter_ali] || @scenario.draft_project_phases.min_by(&:fy_year).team_ali_code #TODO: what should be default here?
    respond_to do |format|
      format.html
    end
    
  end

  #-----------------------------------------------------------------------------
  # New
  #-----------------------------------------------------------------------------
  def new
    @scenario = Scenario.new
    @fiscal_years = (current_fiscal_year_year..current_fiscal_year_year + 49).map{ |y| [fiscal_year(y), y] }
    @organizations =  Organization.all #TODO: Determine correct permissions here
    add_breadcrumb "New Scenario"

    respond_to do |format|
      format.html
    end
    
  end

  #-----------------------------------------------------------------------------
  # Update
  #-----------------------------------------------------------------------------
  def create
    @scenario = Scenario.new 

    respond_to do |format|
      if @scenario.update(form_params)
        format.html { redirect_to scenario_path(@scenario) }
      else
        format.html
      end
    end
    
  end

  #-----------------------------------------------------------------------------
  # Edit
  #-----------------------------------------------------------------------------
  def edit
    set_scenario
    add_breadcrumb @scenario.name

    respond_to do |format|
      format.html
    end
    
  end

  #-----------------------------------------------------------------------------
  # Update
  #-----------------------------------------------------------------------------
  def update
    set_scenario
    respond_to do |format|
      if @scenario.update(form_params)
        format.html { redirect_to scenario_path(@scenario) }
      else
        format.html
      end
    end
    
  end

  #-----------------------------------------------------------------------------
  # Transition States
  # 
  #-----------------------------------------------------------------------------
  def transition
    set_scenario
    prev_state = @scenario.state.titleize

    valid_transitions = @scenario.state_transitions.map(&:event) #Don't let the big bad internet send anything that isn't valid.
    transition = params[:transition]
    @scenario.send(transition) if transition.to_sym.in? valid_transitions

    # c = Comment.new
    # c.comment = prev_state + ": " + transition.to_str.upcase
    # c.creator = current_user
    # @scenario.comments << c
    # @scenario.save

    # redirect_back(fallback_location: root_path) # relying on comment routing to reload the page
  end
    
  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:scenario).permit(Scenario.allowable_params)
  end

  def table_params
    params.permit(:page, :page_size, :search, :sort_column, :sort_order)
  end

  def set_scenario
    @scenario = Scenario.find_by(object_key: params[:id]) 
  end

end
