class User
  include Ripple::Document
  many :addresses
  one :primary_mailing_address, :class_name => "Address"

  one :profile, :using => :key
  one :user_profile

  property :email, String, :presence => true
  many :friends, :class_name => "User"
  one :emergency_contact, :class_name => "User"
  one :credit_card, :using => :key

  one :president_of, :class_name => 'Country', :using => :inverse, :of => :president
end

class UserProfile
  include Ripple::EmbeddedDocument
  property :name, String, :presence => true
  embedded_in :user
end

class Country
  include Ripple::Document

  property :name, String
  property :president_user_id, String, :index => true
  property :citizen_user_ids, Array

  one  :president,:class_name => 'User', :using => :stored_key, :foreign_key => :president_user_id
  many :citizens, :class_name => 'User', :using => :stored_key, :foreign_key => :citizen_user_ids
end
