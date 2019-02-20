FactoryBot.define do

  factory :team_ali_code do
    name { 'Team ALI code 1' }

    factory :replacement_ali_code do
      code { '11.12.XX' }
    end

    factory :rehabilitation_ali_code do
      code { '11.14.XX' }
    end

  end

end
