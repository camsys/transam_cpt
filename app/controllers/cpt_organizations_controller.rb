#------------------------------------------------------------------------------
#
# CptOrganizationsController
#
# Overrides the default Transam Organizations controller
#
#------------------------------------------------------------------------------
class CptOrganizationsController < OrganizationsController
      
  
  # GET /funding_sources/1/edit_budget
  def edit_budget
    
    puts "In CPT edit_budget, params[:id] = #{params[:id]}"
    
    @org = get_org
    
    # See if a budget has been generated for this org, if not we need to create one before
    # we can edit it
    if @org.budgets.empty?
      @org.create_budget(0,0,true)
    end
    
    add_breadcrumb @org.organization_type.name.pluralize(2), organizations_path(:organization_type_id => @org.organization_type.id)
    add_breadcrumb @org.short_name, organization_path(@org)  
    add_breadcrumb "Update Budget"

  end
  
  # PATCH/PUT /funding_sources/1/update_amounts
  # PATCH/PUT /funding_sources/1.json
  def update_budget

    puts "In CPT update_budget, params[:id] = #{params[:id]}"

    @org = get_org

    add_breadcrumb @org.organization_type.name.pluralize(2), organizations_path(:organization_type_id => @org.organization_type.id)
    add_breadcrumb @org.short_name, organization_path(@org)  
    add_breadcrumb "Update Budget"

    respond_to do |format|
      if @org.update(form_params)
        notify_user(:notice, "The budget for #{@org.short_name} was successfully updated.")
        format.html { redirect_to organization_url(@org) }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @org.errors, status: :unprocessable_entity }
      end
    end
  end
  
  protected
  # Returns the agency that has been selected by the user. The agency must
  # be user's agency or one of its member agencies. 
  def get_org
    puts "In CPT get_org, params[:id] = #{params[:id]}"
    super
    if params[:id].nil?
      org = current_user.organization
    else
      org = Organization.find_by_short_name(params[:id])
    end
    if org
      @org = get_typed_organization(org)
    end
  end
    
  
end
