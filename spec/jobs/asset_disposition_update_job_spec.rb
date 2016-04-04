require 'rails_helper'

RSpec.describe AssetDispositionUpdateJob, :type => :job do

  let(:test_asset) { create(:buslike_asset, estimated_replacement_cost: 123) }
  let(:test_line_item) { create(:activity_line_item) }


  it '.run' do
    test_event = test_asset.disposition_updates.create!(attributes_for(:disposition_update_event))
    AssetDispositionUpdateJob.new(test_asset.object_key).run
    test_asset.reload
    
    # check ali updates
    expect(test_line_item.assets).to eq([])
    expect(test_line_item.estimated_cost).to eq(0)

    # check disposition updates  
    expect(test_asset.disposition_date).to eq(Date.today)
    expect(test_asset.disposition_type).to eq(test_event.disposition_type)
    expect(test_asset.service_status_type).to eq(ServiceStatusType.find_by(:code => 'D'))
  end

  it '.prepare' do
    test_asset.save!
    test_line_item.save!
    test_line_item.assets << test_asset
    expect(test_line_item.estimated_cost).to eq(123)

    allow(Time).to receive(:now).and_return(Time.utc(2000,"jan",1,20,15,1))
    expect(Rails.logger).to receive(:debug).with("Executing AssetDispositionUpdateJob at #{Time.now.to_s} for Asset #{test_asset.object_key}")
    
    AssetDispositionUpdateJob.new(test_asset.object_key).prepare
  end
end
