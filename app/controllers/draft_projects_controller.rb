#-------------------------------------------------------------------------------
# Draft Projects Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftProjectsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scenarios", :scenarios_path

  def show
    set_draft_project
    add_breadcrumb "Scenario", scenario_path(@draft_project.scenario)
    add_breadcrumb "#{@draft_project.project_number}"

    respond_to do |format|
      format.html
    end
    
  end

  def edit
    set_draft_project
    add_breadcrumb "Scenario", scenario_path(@draft_project.scenario)
    add_breadcrumb "#{@draft_project.project_number}"
    
    respond_to do |format|
      format.html
    end
  end

  def update
    set_draft_project

    puts form_params
    puts '-Derek-----------------'

    @draft_project.update(form_params)

    respond_to do |format|
      if @draft_project.update(form_params)
        format.html { redirect_to draft_project_path(@draft_project) }
      else
        format.html
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_project).permit(DraftProject.allowable_params)
  end

  def table_params
    params.permit(:page, :page_size, :search, :sort_column, :sort_order)
  end

  def set_draft_project
    @draft_project = DraftProject.find_by(object_key: params[:id]) 
  end

end
