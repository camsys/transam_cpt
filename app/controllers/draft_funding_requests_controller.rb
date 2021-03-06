#-------------------------------------------------------------------------------
# Draft Budgets Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftFundingRequestsController < OrganizationAwareController

  #add_breadcrumb "Home", :root_path


  def create 
    @draft_funding_request = DraftFundingRequest.new 
    @draft_project_phase = DraftProjectPhase.find_by(object_key: draft_project_phase_params[:draft_project_phase_id])
    @draft_funding_request.draft_project_phase = @draft_project_phase

    respond_to do |format|
      if @draft_funding_request.save!
        format.html { redirect_to draft_project_phase_path(@draft_project_phase)}
      else
        format.html
      end
    end
  end

  def destroy
    set_draft_funding_request
    @draft_funding_request.destroy
    redirect_back(fallback_location: root_path)
  end

  def update
    set_draft_funding_request

    respond_to do |format|
      if @draft_funding_request.update(form_params)
        format.json {}
      end
    end
  end

  def lock_total
    set_draft_funding_request
    @draft_project_phase = @draft_funding_request.draft_project_phase

    @draft_funding_request.lock_total(params[:total].to_f)
    
    respond_to do |format|
      format.html { redirect_to draft_project_phase_path(@draft_project_phase)}
      format.json {}
    end
  end


  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_funding_request).permit([:total])
  end

  def set_draft_funding_request
    @draft_funding_request = DraftFundingRequest.find_by(object_key: params[:id]) 
  end

  def draft_project_phase_params
    params.permit(:draft_project_phase_id)
  end

  def autofill_params
    params.permit(:allocation_id)
  end

end
