#-------------------------------------------------------------------------------
# ScenariosController
#
# Basic Scenario CRUD management
#
#-------------------------------------------------------------------------------
class ScenariosController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scenarios", :scenarios_path

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

    respond_to do |format|
      format.html
    end
    
  end

  #-----------------------------------------------------------------------------
  # New
  #-----------------------------------------------------------------------------
  def new
    @scenario = Scenario.new
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
    valid_transitions = @scenario.state_transitions.map(&:event) #Don't let the big bad internet send anything that isn't valid.
    transition = params[:transition]
    @scenario.send(transition) if transition.to_sym.in? valid_transitions
    add_breadcrumb "#{@scenario.state.titleize}"

    redirect_back(fallback_location: root_path)
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
