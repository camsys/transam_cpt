require 'rails_helper'

RSpec.describe Scenario, :type => :model do
  let(:agency_user) { create(:normal_user) }
  let(:grantor_user) { create(:grantor_manager) }
  let(:unrelated_manager) { create(:manager) }
  let(:basic_test_scenario) { create(:scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:unconstrained_scenario) { create(:unconstrained_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:constrained_scenario) { create(:constrained_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:submitted_constrained_scenario) { create(:submitted_constrained_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:submitted_unconstrained_scenario) { create(:submitted_unconstrained_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:final_draft_scenario) { create(:final_draft_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:awaiting_approval_scenario) { create(:awaiting_approval_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:approved_scenario) { create(:approved_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }
  let(:cancelled_scenario) { create(:cancelled_scenario, organization: agency_user.organization, reviewer_organization: grantor_user.organization) }

  describe 'associations' do
    it 'has an organization' do
      expect(basic_test_scenario).to belong_to(:organization)
    end
    it 'has a reviewer organization' do
      expect(basic_test_scenario).to belong_to(:reviewer_organization)
    end
  end

  describe 'validations' do
    it 'must have a name' do
      basic_test_scenario.name = nil
      expect(basic_test_scenario.valid?).to be false
    end
    it 'must have an organization' do
      basic_test_scenario.organization_id = nil
      expect(basic_test_scenario.valid?).to be false
    end
    it 'must have a starting fiscal year' do
      basic_test_scenario.fy_year = nil
      expect(basic_test_scenario.valid?).to be false
    end
    it 'must have an ending fiscal year' do
      basic_test_scenario.ending_fy_year = nil
      expect(basic_test_scenario.valid?).to be false
    end
  end

  it '#allowable_params' do
    expect(Scenario.allowable_params).to eq([
      :organization_id,
      :fy_year,
      :ending_fy_year,
      :name,
      :description,
      :email_updates,
      :reviewer_organization_id,
      :state
    ])
  end

  describe '.updatable_by?' do
    describe 'reviewer user' do
      it 'unconstrained' do
        expect(unconstrained_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'constrained' do
        expect(constrained_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'submitted unconstrained' do
        expect(submitted_unconstrained_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'submitted constrained' do
        expect(submitted_constrained_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'final draft' do
        expect(final_draft_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'awaiting approval' do
        expect(awaiting_approval_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'approved' do
        expect(approved_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'cancelled' do
        expect(cancelled_scenario.updatable_by?(grantor_user)).to be true
      end
      it 'no reviewer_organization' do
        basic_test_scenario.reviewer_organization = nil
        expect(basic_test_scenario.updatable_by?(grantor_user)).to be false
      end
    end
    describe 'agency user' do
      describe 'allowed states' do
        it 'unconstrained' do
          expect(unconstrained_scenario.updatable_by?(agency_user)).to be true
        end
        it 'constrained' do
          expect(constrained_scenario.updatable_by?(agency_user)).to be true
        end
      end
      describe 'unallowed states' do
        it 'submitted unconstrained' do
          expect(submitted_unconstrained_scenario.updatable_by?(agency_user)).to be false
        end
        it 'submitted constrained' do
          expect(submitted_constrained_scenario.updatable_by?(agency_user)).to be false
        end
        it 'final draft' do
          expect(final_draft_scenario.updatable_by?(agency_user)).to be false
        end
        it 'awaiting approval' do
          expect(awaiting_approval_scenario.updatable_by?(agency_user)).to be false
        end
        it 'approved' do
          expect(approved_scenario.updatable_by?(agency_user)).to be false
        end
        it 'cancelled' do
          expect(cancelled_scenario.updatable_by?(agency_user)).to be false
        end
      end
    end
    describe 'unrelated user' do
      it 'unconstrained' do
        expect(unconstrained_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'constrained' do
        expect(constrained_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'submitted unconstrained' do
        expect(submitted_unconstrained_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'submitted constrained' do
        expect(submitted_constrained_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'final draft' do
        expect(final_draft_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'awaiting approval' do
        expect(awaiting_approval_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'approved' do
        expect(approved_scenario.updatable_by?(unrelated_manager)).to be false
      end
      it 'cancelled' do
        expect(cancelled_scenario.updatable_by?(unrelated_manager)).to be false
      end
    end
  end

end
