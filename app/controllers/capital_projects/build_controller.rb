class CapitalProjects::BuildController < OrganizationAwareController

  # Include the wizard functionality
  include Wicked::Wizard

  # Include the fiscal year mixin
  include FiscalYear

  # Session Variables
  SESSION_PROXY_VAR        = "capital_project_builder_cache_var"

  # Set the breadcrumbs
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path
  #add_breadcrumb "New Project", wizard_path(steps.first)

  steps :step1, :step2, :step3, :step4

  def show
    @fiscal_years = get_fiscal_years
    @proxy = session[SESSION_PROXY_VAR]
    if @proxy.nil?
      @proxy = CapitalProjectProxy.new
      session[SESSION_PROXY_VAR] = @proxy
    end
    puts "Show: " + session[SESSION_PROXY_VAR].inspect
    render_wizard
  end


  def update
    @proxy = session[SESSION_PROXY_VAR]
    @proxy.assign_attributes(params[:capital_project_proxy])
    session[SESSION_PROXY_VAR] = @proxy
    puts "Update: " + session[SESSION_PROXY_VAR].inspect
    render_wizard @proxy
  end


  def new
    @proxy = CapitalProjectProxy.new
    # save the proxy in the session
    session[SESSION_PROXY_VAR] = @proxy
    redirect_to wizard_path(steps.first)
  end
  
  def finish_wizard_path
    # Create a new capital project from the proxy and redirect to it
    @proxy = session[SESSION_PROXY_VAR]
    cp = CapitalProject.new
    cp.title = @proxy.name
    cp.description = @proxy.description
    cp.justification = @proxy.justification
    cp.fy_year = @proxy.fiscal_year
    cp.organization = @organization
    cp.team_ali_code = @proxy.scope
    cp.emergency = false
    cp.active = true
    cp.capital_project_status_type_id = 1
    cp.capital_project_type_id = @proxy.capital_project_type
    
    if cp.save
      msg = "The capital project was sucessfully created."
      notify_user(:notice, msg)
      capital_project_path(cp)
      return
    else
      msg = "A problem occurred while saving your capital project."
      notify_user(:alert, msg)
    end
  end  
  
end