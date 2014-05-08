class TeamAliCode < ActiveRecord::Base
  # Add the nested set behavior to this model so it becomes a tree
  acts_as_nested_set
          
  # default scope
  default_scope { where(:active => true) }
  
  def full_name
    "#{code} #{name}"
  end
  def to_s
    code
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
  
end

