class LocGroup < ActiveRecord::Base
  belongs_to :department
  belongs_to :view_permission,
              :class_name => "Permission",
              :foreign_key => "view_perm_id",
              :dependent => :destroy
  belongs_to :signup_permission,
              :class_name => "Permission",
              :foreign_key => "signup_perm_id",
              :dependent => :destroy
  belongs_to :admin_permission,
              :class_name => "Permission",
              :foreign_key => "admin_perm_id",
              :dependent => :destroy
  has_many :locations, :dependent => :destroy
  
  named_scope :active, :conditions => {:active => true}
  
  before_validation_on_create :create_permissions
  before_validation_on_update :update_permissions

  validates_presence_of :department

  def permissions
    [view_permission, signup_permission, admin_permission]
  end   

  # Conventional has_many :through won't work -Ben
  def data_objects
    self.locations.map{|loc| loc.data_objects}.flatten.compact
  end

  def users
    department.users.select { |u| u.can_signup?(self) }
  end
  
  def roles
      department.roles.select { |u| u.permissions.include?(signup_permission) }
  end
  
  def deactivate
    self.active = false
    self.save!
    self.locations.each do |location|
     location.deactivate 
    end
  end
  
  def activate
    self.active = true
    self.save!
    self.locations.each do |location|
      location.activate
    end
  end

  private

  def create_permissions
    self.create_view_permission(:name => name + " view")
    self.create_signup_permission(:name => name + " signup")
    self.create_admin_permission(:name => name + " admin")
  end

  # in case loc group name is changed, update permission names accordingly
  # note update_attribute does the saving as well
  def update_permissions
    self.view_permission.update_attribute(:name, name + " view")
    self.signup_permission.update_attribute(:name, name + " signup")
    self.admin_permission.update_attribute(:name, name + " admin")
  end


end
