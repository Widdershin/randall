
class ForgetTournamentResults
  def initialize(slug:)
    @tournament = Tournament.find_by(slug: slug)
  end

  def call
    ActiveRecord::Base.transaction do
      @tournament.events.each do |event|
        event.point_changes.each do |change|
          change.player.update!(points: change.player.points - change.point_change)
        end
      end

      @tournament.destroy!
    end
  end
end
