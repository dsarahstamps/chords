class Site < ActiveRecord::Base
  has_many :instruments
  default_scope { order(name: 'ASC') }
  
  def self.initialize
  end
  
  def self.list_site_options 
      Site.select("id, name").map {|site| [site.id, site.name] }
  end  
end
