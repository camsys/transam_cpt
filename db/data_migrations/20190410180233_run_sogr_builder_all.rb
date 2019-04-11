class RunSogrBuilderAll < ActiveRecord::DataMigration
  def up
    orgs = TransitOperator.all

    orgs.each do |o|
      builder = CapitalProjectBuilder.new

      TransamAsset.where(replacement_status_type_id: ReplacementStatusType.find_by(name: 'Pinned').id).where('scheduled_replacement_year >= 2019').update_all(replacement_status_type_id: ReplacementStatusType.find_by(name: 'By Policy').id)
      num_created = builder.build(o) # uses default options

      puts "#{num_created} SOGR capital projects were added to #{o.short_name}'s capital needs list."
    end
  end
end