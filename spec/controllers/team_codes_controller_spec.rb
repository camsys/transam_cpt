require 'rails_helper'

RSpec.describe TeamCodesController, :type => :controller do

  before(:each) do
    TeamAliCode.destroy_all
  end

  describe 'GET children' do
    it 'get by id' do
      parent = create(:rehabilitation_ali_code)
      child = create(:rehabilitation_ali_code, :parent => parent)

      get :children, params:{:id => parent.id, :format => :json}
      expect(assigns(:results)).to include(child)
    end
    it 'get by code' do
      parent = create(:rehabilitation_ali_code)
      child = create(:rehabilitation_ali_code, :parent => parent)

      puts parent.children.inspect

      get :children, params:{:code => parent.code, :format => :json}
      expect(assigns(:results)).to include(child)
    end
    it 'no ali' do
      get :children, params:{:format => :json}
      expect(assigns(:results)).to eq([])
    end

    it 'no children returns itself' do
      parent = create(:rehabilitation_ali_code)
      child = create(:rehabilitation_ali_code, :parent => parent)

      get :children, params:{:id => child.id, :format => :json}
      expect(assigns(:results)).to eq([child])
    end
  end
end
