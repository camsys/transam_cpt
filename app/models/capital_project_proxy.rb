class CapitalProjectProxy < Proxy

  attr_accessor :name
  attr_accessor :fiscal_year
  attr_accessor :mode
  attr_accessor :capital_project_type
  attr_accessor :category
  attr_accessor :description
  attr_accessor :justification

  def initialize(attrs = {})
    super
    attrs.each do |k, v|
      self.send "#{k}=", v
    end
    set_defaults
  end
  protected

  # Set resonable defaults for a new capital project
  def set_defaults

  end

end
