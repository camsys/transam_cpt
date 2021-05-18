#-------------------------------------------------------------------------------
# Draft Budgets Controller
#
# Basic Draft ProjectCRUD management
#
#-------------------------------------------------------------------------------
class DraftBudgetsController < OrganizationAwareController

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Budgets", :draft_budgets_path

  def index
    @draft_budgets= DraftBudget.all 

    respond_to do |format|
      format.html
    end

  end

  def show
    set_draft_budget
    add_breadcrumb "#{@draft_budget.name}"

    respond_to do |format|
      format.html
    end
    
  end

  def edit
    set_draft_budget
    add_breadcrumb "#{@draft_budget.name}"
    
    @funding_templates = FundingTemplate.joins(:organizations).where(funding_templates_organizations: {organization_id: current_user.viewable_organizations})
    #@funding_templates = FundingTemplate.all
    
    respond_to do |format|
      format.html
    end
  end

  def new 
    @draft_budget = DraftBudget.new 
    add_breadcrumb "New Budget"

    @funding_templates = FundingTemplate.joins(:organizations).where(funding_templates_organizations: {organization_id: current_user.viewable_organizations})

    respond_to do |format|
      format.html
    end
  end

  def create 
    @draft_budget = DraftBudget.new 

    respond_to do |format|
      if @draft_budget.update(form_params)
        format.html { redirect_to draft_budget_path(@draft_budget) }
      else
        format.html
      end
    end
  end

  def update
    set_draft_budget

    respond_to do |format|
      if @draft_budget.update(form_params)
        format.html { redirect_to draft_budget_path(@draft_budget) }
      else
        format.html
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:draft_budget).permit(DraftBudget.allowable_params)
  end

  def table_params
    params.permit(:page, :page_size, :search, :sort_column, :sort_order)
  end

  def set_draft_budget
    @draft_budget = DraftBudget.find_by(object_key: params[:id]) 
  end

end
