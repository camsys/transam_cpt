# Technique caged from http://stackoverflow.com/questions/4460800/how-to-monkey-patch-code-that-gets-auto-loaded-in-rails
Rails.configuration.to_prepare do
  TransitAsset.class_eval do
    include TransamCpt::TransamPlannable
  end
  TransitAgency.class_eval do
    include TransamCpt::TransamPlanningOrganization
  end
end