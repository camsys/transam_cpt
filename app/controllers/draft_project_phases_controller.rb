#-------------------------------------------------------------------------------
# Draft Projects Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftProjectPhasesController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Scenarios", :scenarios_path

  def show
    set_draft_project_phase
    add_breadcrumb @draft_project_phase.draft_project.scenario.name, scenario_path(@draft_project_phase.draft_project.scenario)
    add_breadcrumb @draft_project_phase.draft_project.title, draft_project_path(@draft_project_phase.draft_project)
    add_breadcrumb "#{@draft_project_phase.name}"

    @draft_budgets = DraftBudget.active.where(owner: @draft_project_phase.organization)
    @draft_budgets += DraftBudget.active.placeholder 
    @draft_budgets += DraftBudget.active.shared 
    @draft_budgets.uniq!
    @is_grantor = current_user.organization.grantor?
    
    respond_to do |format|
      format.html
    end
  end

  def edit
    set_draft_project_phase
    add_breadcrumb @draft_project_phase.draft_project.scenario.name, scenario_path(@draft_project_phase.draft_project.scenario)
    add_breadcrumb @draft_project_phase.draft_project.title, draft_project_path(@draft_project_phase.draft_project)
    add_breadcrumb "#{@draft_project_phase.name}"
    
    respond_to do |format|
      format.html
    end
  end

  def update
    set_draft_project_phase 
    respond_to do |format|
      if @draft_project_phase.update(form_params)
        @draft_project_phase.set_estimated_cost
        format.html { redirect_to draft_project_phase_path(@draft_project_phase) }
        format.json { render json: true }
      else
        format.html
        format.json { render json: false }
      end
    end
  end

  def new 
    @draft_project_phase = DraftProjectPhase.new 

    @draft_project = DraftProject.find_by(object_key: draft_project_params[:draft_project_id])
    @draft_project_phase.draft_project = @draft_project
    add_breadcrumb @draft_project_phase.draft_project.scenario.name, scenario_path(@draft_project_phase.draft_project.scenario)
    add_breadcrumb @draft_project_phase.draft_project.title, draft_project_path(@draft_project_phase.draft_project)
    add_breadcrumb "New Project Phase"

    respond_to do |format|
      format.html
    end
  end


  def create 
    @draft_project_phase = DraftProjectPhase.new 

    respond_to do |format|
      if @draft_project_phase.update(form_params)
        funding_updated = true
        @draft_project_phase.draft_funding_requests.each do |r|
          if !r.lock_total(@draft_project_phase.cost)
            funding_updated = false
          end
        end
        if funding_updated
          format.html { redirect_to draft_project_path(@draft_project_phase.draft_project) }
        else
          format.html
        end
      else
        format.html
      end
    end
  end

  def destroy
    set_draft_project_phase
    project = @draft_project_phase.draft_project
    @draft_project_phase.destroy


    respond_to do |format|
      format.html { redirect_to draft_project_path(project) }
      format.json { render json: true }
    end
  end


  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_project_phase).permit(DraftProjectPhase.allowable_params)
  end

  def set_draft_project_phase
    @draft_project_phase = DraftProjectPhase.find_by(object_key: params[:id]) 
  end

  def draft_project_params
    params.permit(:draft_project_id)
  end

end
