require 'rails_helper'

RSpec.describe TeamCodesController, :type => :controller do

  before(:each) do
    TeamAliCode.destroy_all
  end

  describe 'GET children' do
    it 'get by id' do
      parent = create(:rehabilitation_ali_code)
      child = create(:rehabilitation_ali_code, :parent => parent)

      get :children, :id => parent.id, :format => :json
      expect(assigns(:results)).to include(child)
    end
    it 'get by code' do
      parent = create(:rehabilitation_ali_code)
      child = create(:rehabilitation_ali_code, :parent => parent)

      puts parent.children.inspect

      get :children, :code => parent.code, :format => :json
      expect(assigns(:results)).to include(child)
    end
    it 'no ali' do
      get :children, :format => :json
      expect(assigns(:results)).to eq([])
    end

    it 'no children' do
      parent = create(:rehabilitation_ali_code)
      child = create(:rehabilitation_ali_code, :parent => parent)

      get :children, :id => child.id, :format => :json
      expect(assigns(:results)).to eq([])
    end
  end
end
