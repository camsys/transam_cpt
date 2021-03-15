#-------------------------------------------------------------------------------
# Draft Budgets Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftBudgetAllocationsController < OrganizationAwareController

  #add_breadcrumb "Home", :root_path

  def edit
    set_draft_budget_allocation
    @draft_budgets = DraftBudget.all 
    
    respond_to do |format|
      format.html
    end
  end

  def new 
    @draft_budgets = DraftBudget.all 
    @draft_budget_allocation = DraftBudgetAllocation.new 
    @draft_funding_request = DraftFundingRequest.find_by(object_key: draft_funding_request_params[:draft_funding_request_id])
    @draft_budget_allocation.draft_funding_request = @draft_funding_request

    respond_to do |format|
      format.html
    end
  end

  def create 
    @draft_budget_allocation = DraftBudgetAllocation.new 
    respond_to do |format|
      if @draft_budget_allocation.update(form_params)
        format.html { redirect_to draft_project_phase_path(@draft_budget_allocation.draft_project_phase)}
      else
        format.html
      end
    end
  end

  def update
    set_draft_budget_allocation

    respond_to do |format|
      if @draft_budget_allocation.update(form_params)
        format.html { redirect_to draft_project_phase_path(@draft_budget_allocation.draft_project_phase) }
      else
        format.html
      end
    end
  end

  def destroy
    set_draft_budget_allocation
    @draft_budget_allocation.destroy
    redirect_back(fallback_location: root_path)
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_budget_allocation).permit(DraftBudgetAllocation.allowable_params)
  end

  def set_draft_budget_allocation
    @draft_budget_allocation = DraftBudgetAllocation.find_by(object_key: params[:id]) 
  end

  def draft_funding_request_params
    params.permit(:draft_funding_request_id)
  end

end
