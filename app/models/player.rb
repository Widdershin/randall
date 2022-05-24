
class Player < ActiveRecord::Base
  has_many :point_changes, dependent: :destroy
  has_many :events, :through => :point_changes, dependent: :destroy

  def name
    if sponsor.present?
      "#{sponsor} | #{tag}"
    else
      tag
    end
  end
end
