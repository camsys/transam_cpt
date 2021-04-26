#-------------------------------------------------------------------------------
# Draft Budgets Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftProjectPhaseAssetsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path

  def show
    set_scenario
    set_transit_asset
    set_draft_project_phase_asset
    #add_breadcrumb "#{@draft_budget.name}"
    @phases = @scenario.draft_project_phases.map{ |p| [p.name, p.object_key] }

    respond_to do |format|
      format.html
    end
    
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    #params.require(:draft_budget).permit(DraftBudget.allowable_params)
  end

  def set_scenario
    @scenario = Scenario.find_by(object_key: params[:scenario_id])
  end

  def set_transit_asset
    @transit_asset = TransitAsset.find_by(object_key: params[:id])
  end

  def set_draft_project_phase_asset
    @draft_project_phase_asset = @scenario.draft_project_phase_assets.where(transit_asset: @transit_asset).first
  end

end
