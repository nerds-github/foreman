class Permission < ApplicationRecord
  validates_lengths_from_database
  validates :name, :presence => true, :uniqueness => true

  has_many :filterings, :dependent => :destroy
  has_many :filters, :through => :filterings

  has_many :roles, :through => :filters

  scoped_search :on => :id, :complete_enabled => false, :only_explicit => true, :validator => ScopedSearch::Validators::INTEGER
  scoped_search :on => :name, :complete_value => true
  scoped_search :on => :resource_type

  def self.resources
    # We don't run seeds.rb initializer in test environment, so at the first call of this method in TemplateInputsController
    # during code loading @all_resources will be an empty array, and don't get populated with the actual resources from db later
    # In dev and prod environments, the seeds.rb initializer is run, so @all_resources will be populated with the actual resources
    @all_resources = Permission.distinct.order(:resource_type).pluck(:resource_type).compact if @all_resources.empty?
    @all_resources
  end

  def self.resources_with_translations
    with_translations.sort_by(&:first)
  end

  def self.with_translations
    resources.map { |r| [_(Filter.get_resource_class(r).try(:humanize_class_name) || r), r] }
  end

  def self.reset_resources
    @all_resources = nil
  end

  # converts klass to name used as resource_type in permissions table
  def self.resource_name(klass)
    return 'Operatingsystem' if klass <= Operatingsystem
    return 'ComputeResource' if klass <= ComputeResource
    return 'Subnet' if klass <= Subnet
    return 'Parameter' if klass <= Parameter
    return 'AuthSource' if klass <= AuthSource
    return 'Setting' if klass <= Setting

    case (name = klass.to_s)
    when 'Audited::Audit'
      'Audit'
    when /\AHost::.*\Z/
      'Host'
    else
      name
    end
  end
end
