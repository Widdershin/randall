# frozen_string_literal: true

require 'discordrb'

# As a TO, I want to submit results and have points updated, then print them out
#
# We have Players
#   - start_gg_id
#   - name
#   - event results
#
# We have point changes
#   - po

bot = Discordrb::Bot.new(token: ENV.fetch('DISCORD_BOT_TOKEN'))

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

# This method call adds an event handler that will be called on any message that exactly contains the string "Ping!".
# The code inside it will be executed, and a "Pong!" response will be sent to the channel.

bot.message(start_with: '.randal') do |event|
  begin
    handle_message(event)
  rescue Exception => e
    event.respond("Randall encountered an error!")
    raise
  end
  nil
end

def handle_message(event)
  notifier, command, *args = event.text.split(" ")

  user_is_admin = event.author.roles.any? { |role| role.permissions.administrator }

  return nil unless notifier == ".randal" || notifier == ".randall"
  return event.respond "Sorry, randall only talks to admins right now." unless user_is_admin
  return event.respond "Unrecognized command: #{command}\nAvailable commands: #{RandallCommands.methods(false).join(', ')}" unless RandallCommands.respond_to?(command)

  RandallCommands.send(command, event, args)
end

module RandallCommands
  def self.record(event, args)
    self.submit(event, args)
  end

  def self.submit(event, args)
    bracket_url = args.first

    begin
      summary = RecordTournamentResults.new(bracket_url: bracket_url).call
      event.respond("Recorded results!")
      print_slowly(event, summary)
    rescue InvalidTournamentURLException => e
      event.respond("I couldn't figure out that tournament url sorry! It should be something like https://www.start.gg/tournament/love-to-see-it-respawn-fundraiser/details")
    rescue InvalidResponseException => e
      event.respond("Hmmm, I can't seem to talk to start.gg right now.")
    rescue AlreadyRecordedTournamentException => e
      event.respond("We've already recorded that tournament before!")
    end
  end

  def self.print_slowly(event, message)
    lines = message.split("\n")

    smaller_message = ""

    max_iterations = lines.count * 2
    iterations = 0

    until lines.empty? || iterations >= max_iterations do
      line = lines.first

      if line.length >= 1000
        fail "line too long"
      end

      if ((line.length + 2) + smaller_message.length) < 1000
        smaller_message += line + "\n"
        lines.shift
      else
        event.respond(smaller_message)
        sleep 0.5
        smaller_message = ""
      end

      iterations += 1
    end

    event.respond(smaller_message) if smaller_message.present?
  end

  def self.rankings(event, args)
    results = ""

    Player.order('points DESC').each_with_index do |player, index|
      results += "##{index + 1} - #{player.name} (#{player.points} points)\n"
    end

    print_slowly(event, results)
  end

  def self.tournaments(event, args)
    results = "Recently recorded tournaments:\n"

    Tournament.order('created_at DESC').each_with_index do |tournament|
      results += "• #{tournament.name} (#{tournament.url} - id: #{tournament.slug})\n"
    end

    event.respond(results)
  end

  def self.forget(event, args)
    slug = args.first

    ForgetTournamentResults.new(slug: slug).call

    event.respond("Forgot all about it!")
  end
end

# This method call has to be put at the end of your script, it is what makes the bot actually connect to Discord. If you
# leave it out (try it!) the script will simply stop and the bot will not appear online.
bot.run
