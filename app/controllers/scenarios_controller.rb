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
    @scenario = Scenario.find_by(object_key: params[:id]) 

    respond_to do |format|
      format.html
    end
    
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:scenarios).permit(Scenario.allowable_params)
  end

  def table_params
    params.permit(:page, :page_size, :search, :sort_column, :sort_order)
  end

end
