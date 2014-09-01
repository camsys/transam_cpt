class TeamAliCode < ActiveRecord::Base
  # Add the nested set behavior to this model so it becomes a tree
  acts_as_nested_set
          
  # default scope
  default_scope { where(:active => true) }
  scope :all_categories, -> { where("code REGEXP '[1-4]{2}.[1-9]{2}.XX'") }
  scope :bus_categories, -> { where("code REGEXP '11.[1-9]{2}.XX'") }
  scope :fixed_guideway_categories, -> { where("code REGEXP '12.[1-9]{2}.XX'") }
  scope :top_level_categories, -> { where("code REGEXP '[1-4]{2}.XX.XX'") }
  
  def full_name
    "#{code} #{name}"
  end
  def description(join_str = '->')
    a = []
    a << context(join_str)
    a << "#{name} (#{code})"
    a.join(join_str)
  end
  def to_s
    code
  end
  # Return the context for a code. The context is the predecessors as a string
  def context(join_str = '->')
    a = []
    x = self
    while x.parent
      x = x.parent
      a << x.name
    end
    a.reverse.join(join_str)
  end
  def scope
    elems = code.split('.')
    "#{elems[0]}#{elems[1].first}"
  end
  def type
    code.split('.')[0]
  end
  def category
    code.split('.')[1]
  end
  def sub_category
    code.split('.')[2]
  end
  def type_and_category
    elems = code.split('.')
    "#{elems[0]}.#{elems[1]}"
  end
  # Returns true if the ALI requires one or more vehicles to be deliverd
  # categories XX.12.XX, XX.13.XX, XX.16.XX, XX.18.XX
  def is_vehicle_delivery?
    ['12', '13', '16', '18'].include? category
  end
end

