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
    @fy_year = allowed_params[:fy_year] || current_fiscal_year_year
    @scenarios = Scenario.where(fy_year: @fy_year, organization: current_user.viewable_organizations)

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

  def assets
    set_scenario
    add_breadcrumb "#{@scenario.name} Assets"

    @transit_assets = TransitAsset.where(organization: @scenario.organization)

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
        format.json { render json: true}
      else
        format.html
        format.json { render json: false}
      end
    end
    
  end

  #-----------------------------------------------------------------------------
  # Copy
  #-----------------------------------------------------------------------------
  def copy
    set_scenario
    @scenario = @scenario.copy 
    respond_to do |format|
      format.html { redirect_to scenario_path(@scenario) }
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

    if !@scenario.validate_transition transition 
      error =  @scenario.errors.try(:first) 
      if error
        flash.alert = error.try(:last)
      end
    else 
      @scenario.send(transition) if transition.to_sym.in? valid_transitions

      if @scenario.email_updates
        @scenario.send_transition_email(transition)
      end

      c = Comment.new
      c.comment = prev_state + ": " + transition.to_str.upcase
      c.creator = current_user
      @scenario.comments << c
      @scenario.save
    end 

    redirect_back(fallback_location: root_path)
  end

  #-----------------------------------------------------------------------------
  # Transition States
  # 
  #-----------------------------------------------------------------------------
  def dotgrants_export
    set_scenario
    #render json: @scenario.dotgrants_json
    respond_to do |format|
      format.html { send_data @scenario.dotgrants_json, filename: "#{@scenario.organization.try(:short_name)}_dotgrants.json",type: :json, disposition: "attachment" }
    end
  end
    
  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:scenario).permit(Scenario.allowable_params)
  end

  def allowed_params
    params.permit(:fy_year)
  end

  def set_scenario
    @scenario = Scenario.find_by(object_key: params[:id]) 
  end

end
