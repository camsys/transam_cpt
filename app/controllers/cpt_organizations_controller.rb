#------------------------------------------------------------------------------
#
# CptOrganizationsController
#
# Overrides the default Transam Organizations controller
#
#------------------------------------------------------------------------------
class CptOrganizationsController < OrganizationsController
      
  
  
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
