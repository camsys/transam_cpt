#-------------------------------------------------------------------------------
# Draft Budgets Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftProjectPhaseAssetsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path

  def edit
    set_scenario
    set_transit_asset
    set_draft_project_phase_asset_from_scenario
    #add_breadcrumb "#{@draft_budget.name}"
    @phases = @scenario.draft_project_phases.map{ |p| [p.long_name, p.id] }
    @phases.sort_by! {|phase| phase.first }


    respond_to do |format|
      format.html
    end
    
  end

  def new
    set_scenario
    set_transit_asset
    @draft_project_phase_asset = DraftProjectPhaseAsset.new
    @draft_project_phase_asset.transit_asset = @transit_asset
    @phases = @scenario.draft_project_phases.map{ |p| [p.long_name, p.id] }
    @phases.sort_by! {|phase| phase.first }

    respond_to do |format|
      format.html
    end
    
  end

  def update
    set_draft_project_phase_asset
    @scenario = @draft_project_phase_asset.scenario
    phase_id = form_params[:draft_project_phase_id]
    if phase_id.nil?
      @draft_project_phase_asset.delete 
    else
      @draft_project_phase_asset.update(form_params)
    end
    redirect_to scenario_path(@scenario)
  end

  def create
    @draft_project_phase_asset = DraftProjectPhaseAsset.new 
    @draft_project_phase_asset.update(form_params)
    redirect_to scenario_path(@draft_project_phase_asset.scenario)
  end


  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_project_phase_asset).permit(DraftProjectPhaseAsset.allowable_params)
  end

  def set_scenario
    @scenario = Scenario.find_by(object_key: params[:scenario_id])
  end

  def set_transit_asset
    @transit_asset = TransitAsset.find_by(object_key: params[:transit_asset_id])
  end

  def set_draft_project_phase_asset
    @draft_project_phase_asset = DraftProjectPhaseAsset.find_by(object_key: params[:id])
  end

  def set_draft_project_phase_asset_from_scenario
    @draft_project_phase_asset = @scenario.draft_project_phase_assets.where(transit_asset: @transit_asset).first
  end

end
