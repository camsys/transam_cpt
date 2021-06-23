#-------------------------------------------------------------------------------
# Milestones Controller
#-------------------------------------------------------------------------------
class MilestonesController < OrganizationAwareController

  def update
    set_milestone

    respond_to do |format|
      if @milestone.update(form_params)
        unless form_params["milestone_date"].blank?
          @milestone.milestone_date = DateTime.strptime(form_params["milestone_date"], "%m/%d/%Y")
          @milestone.save
        end
        format.html { redirect_to draft_project_phase_path(@milestone.draft_project_phase) }
      else
        format.html
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def form_params
    params.require(:milestone).permit(Milestone.allowable_params)
  end

  def set_milestone
    @milestone = Milestone.find_by(object_key: params[:id]) 
  end

end
