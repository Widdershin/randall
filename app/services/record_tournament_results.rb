
class InvalidTournamentURLException < StandardError; end
class InvalidResponseException < StandardError; end
class AlreadyRecordedTournamentException < StandardError; end

class RecordTournamentResults
  ALLOWED_HOSTS = ["www.start.gg", "start.gg", "smash.gg", "www.smash.gg"].freeze
  START_GG_API_KEY = ENV.fetch('START_GG_API_KEY')
  START_GG_API_ENDPOINT = "https://api.start.gg/gql/alpha"
  QUERY = <<~GRAPHQL
    query TournamentQuery($slug: String) {
      tournament(slug: $slug){
        id
        name
        url
        events {
          id
          name
          entrants {
            nodes {
              initialSeedNum
              participants {
                player {
                  id
                }
                gamerTag
                prefix
                requiredConnections {
                  type
                  externalUsername
                  externalId
                }
              }
              standing {
                placement
              }
              paginatedSets(sortType:RECENT) {
                nodes {
                  winnerId
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def initialize(bracket_url:)
    bracket_url = "https://" + bracket_url unless bracket_url.start_with?("https://")
    @bracket_url = bracket_url
  end

  def get_slug
    uri = URI(@bracket_url)
    path_components = uri.path.split('/')

    if !(ALLOWED_HOSTS.include?(uri.host)) || path_components[1] != "tournament"
      return nil
    end

    path_components[2]
  end

  def call
    summary = []
    slug = get_slug

    if slug.nil?
      raise InvalidTournamentURLException, @bracket_url
    end

    response = HTTP.auth("Bearer #{START_GG_API_KEY}").post(START_GG_API_ENDPOINT, json: {
      "query": QUERY,
      "variables": { "slug": slug },
      "operationName":"TournamentQuery"
    })

    unless response.status.success?
      raise InvalidResponseException, response
    end

    json = JSON.parse(response.body.to_s)

    tournament_data = json.dig("data", "tournament")

    if Tournament.find_by(start_gg_id: tournament_data["id"])
      raise AlreadyRecordedTournamentException
    end

    ActiveRecord::Base.transaction do
      tournament = Tournament.create!(
        name: tournament_data["name"],
        url: tournament_data["url"],
        start_gg_id: tournament_data["id"],
        slug: slug
      )

      summary << tournament.name

      tournament_data["events"].each do |event_data|
        event = tournament.events.create!(
          name: event_data["name"],
          start_gg_id: event_data["id"]
        )

        summary << ""
        summary << event.name
        summary << ""

        player_count = event_data.dig("entrants", "nodes").count

        event_data.dig("entrants", "nodes").each do |player_data|
          tag = player_data.dig("participants", 0, "gamerTag")
          sponsor = player_data.dig("participants", 0, "prefix") || ""

          player = Player.create_with(
            points: 0,
            tag: player_data.dig("participants", 0, "gamerTag"),
            sponsor: sponsor
          ).find_or_create_by!(start_gg_id: player_data.dig("participants", 0, "player", "id"))

          player.update!(
            tag: tag,
            sponsor: sponsor
          )
          player.points ||= 0

          placement = player_data.dig("standing", "placement")
          seed = player_data.dig("initialSeedNum")

          if placement.nil?
            next
          end

          ranking_points = (player_count - placement) + 1
          seed_points = 0
          point_change_cause = "Placed ##{placement}/#{player_count}, earning #{ranking_points} ranking points."

          if placement < seed
            seed_points = seed - placement
            point_change_cause += "\nSeeded ##{seed}, placed ##{placement}, earning #{seed_points} seed points"
          end

          summary << "#{player.name} - #{point_change_cause}".gsub("\n", " ")
          point_change = ranking_points + seed_points

          player.point_changes.create!(
            cause: point_change_cause,
            point_change: point_change,
            event: event
          )

          player.points += point_change

          player.save!
        end
      end
    end

    summary.join("\n")
  end
end
