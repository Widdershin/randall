
class Event < ActiveRecord::Base
  has_many :point_changes, dependent: :delete_all
end
