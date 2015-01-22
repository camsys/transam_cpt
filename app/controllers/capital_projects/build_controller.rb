class CapitalProjects::BuildController < OrganizationAwareController

  # Include the wizard functionality
  include Wicked::Wizard

  # Include the fiscal year mixin
  include FiscalYear

  # Session Variables
  CACHE_PROXY_VAR        = "capital_project_builder_cache_var"

  # Set the breadcrumbs
  add_breadcrumb "Home", :root_path
  add_breadcrumb "Capital Projects", :capital_projects_path

  steps :step1, :step2, :step3, :step4, :step5

  def show
    Rails.logger.debug "in show : step = #{step}"

    add_breadcrumb "New"

    @fiscal_years = get_fiscal_years
    @proxy = get_cached_objects(get_cache_key(current_user, CACHE_PROXY_VAR))
    if @proxy.blank?
      @proxy = CapitalProjectProxy.new
      cache_objects(get_cache_key(current_user, CACHE_PROXY_VAR), @proxy)
    end
    #puts "Show: " + session[SESSION_PROXY_VAR].inspect
    #puts "Step = " + step.to_s

    # if this is the last step then save the object
    if step == 'wicked_finish'
      save_new_project(@proxy)
    end

    render_wizard
  end


  def update
    Rails.logger.debug "in update : step = #{step}"

    @proxy = get_cached_objects(get_cache_key(current_user, CACHE_PROXY_VAR))
    @proxy.assign_attributes(params[:capital_project_proxy])
    cache_objects(get_cache_key(current_user, CACHE_PROXY_VAR), @proxy)

    render_wizard @proxy
  end


  def new
    @proxy = CapitalProjectProxy.new
    # save the proxy in the session
    cache_objects(get_cache_key(current_user, CACHE_PROXY_VAR), @proxy)
    redirect_to wizard_path(steps.first)
  end

  def finish_wizard_path
    capital_project_path(session[:new_project_object_key])
  end

  protected

  def save_new_project(proxy)

    puts "Saving proxy: #{proxy.inspect}"
    # Create a new capital project from the proxy and redirect to it
    cp = CapitalProject.new
    cp.title = proxy.name
    cp.description = proxy.description
    cp.justification = proxy.justification
    cp.fy_year = proxy.fiscal_year
    cp.organization = @organization
    cp.team_ali_code = proxy.scope(5)
    cp.emergency = false
    cp.active = true
    cp.capital_project_type = CapitalProjectType.find_by_name(proxy.capital_project_type)

    if cp.save
      puts "Save Worked #{cp.inspect}"
      msg = "The capital project was sucessfully created. The number is #{cp.project_number}"
      session[:new_project_object_key] = cp.object_key
      notify_user(:notice, msg)
    else
      puts "Save failed: #{cp.errors.inspect}"
      msg = "A problem occurred while saving your capital project."
      notify_user(:alert, msg)
    end

  end

end
