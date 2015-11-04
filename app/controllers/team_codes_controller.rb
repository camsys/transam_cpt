#-------------------------------------------------------------------------------
# TeamCodesController
#
# Various restful methods for working with TEAM ALI codes. These are usually
# called via AJAX
#-------------------------------------------------------------------------------
class TeamCodesController < ApplicationController

  #-----------------------------------------------------------------------------
  # Returns the children of a TEAM Code
  #-----------------------------------------------------------------------------
  def children

    if params[:id].present?
      code = TeamAliCode.find(params[:id])
    elsif params[:code].present?
      code = TeamAliCode.find_by(:code => params[:code])
    else
      code = nil
    end

    if code.present?
      @results = code.children
    else
      @results = []
    end

    respond_to do |format|
      # respond with the created JSON object
      format.js   { render json: @results }
      format.json { render json: @results }
    end

  end

  #-----------------------------------------------------------------------------
  protected
  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  private
  #-----------------------------------------------------------------------------

end
