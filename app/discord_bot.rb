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

SMASH_ULTIMATE_CHARACTERS = %w{
  Mario
  Donkey Kong
  Link
  Samus Aran
  Yoshi
  Kirby
  Fox McCloud
  Pikachu
  Dark Samus
  Luigi
  Ness
  Captain Falcon
  Jigglypuff
  Princess Peach
  Princess Daisy
  Bowser
  Ice Climbers
  Sheik
  Princess Zelda
  Dr. Mario
  Pichu
  Falco Lombardi
  Marth
  Lucina*
  Young Link
  Ganondorf
  Mewtwo
  Roy
  Chrom
  Mr. Game & Watch
  Meta Knight
  Pit
  Dark Pit
  Zero Suit Samus
  Wario
  Solid Snake
  Ike
  Pokémon Trainer
  Diddy Kong
  Lucas
  Sonic
  King Dedede
  Pikmin and Olimar
  Lucario
  R.O.B.
  Toon Link
  Wolf
  Villager
  Mega Man
  Wii Fit Trainer
  Rosalina and Luma
  Little Mac
  Greninja
  Palutena
  Pac-Man
  Robin
  Shulk
  Bowser Jr.
  Duck Hunt
  Ryu
  Ken
  Cloud Strife
  Corrin
  Bayonetta
  Inkling
  Ridley
  Simon
  Richter
  King K. Rool
  Isabelle
  Incineroar
  Mii Brawler
  Mii Swordfighter
  Mii Gunner
  Piranha Plant
  Joker
  Hero
  Banjo and Kazooie
  Terry
  Byleth
  Min Min
  Steve
  Sephiroth
  Pyra/Mythra
  Kazuya Mishima
  Sora
}

bot.message(start_with: '.randal') do |event|
  process_event(event, :message)
end

bot.mention do |event|
  process_event(event, :mention)
end

def process_event(event, source)
  begin
    handle_message(event, source)
  rescue Exception => e
    event.respond("Randall encountered an error!")
    raise
  end

  if event.text.split(" ").first == ".randal"
    if rand(100) == 14
      sleep 1
      event.respond("It's Randall, by the way. Not Randal.")
    end
  end
  nil
end

def handle_message(event, source)
  notifier, command, *args = event.text.split(" ")
  command = command.to_s.downcase

  return nil if source == :message && !(notifier == ".randal" || notifier == ".randall")

  user_is_admin = event.author.roles.any? { |role| role.permissions.administrator || role.permissions.manage_server{  } }

  role = :user

  if user_is_admin
    role = :admin
  end

  commands = RandallCommands.available_commands(role)

  return event.respond(<<~TEXT) unless commands.include?(command.to_s)
    Howdy 👋
    Available commands:
    #{commands.map { |command| " • #{command}" }.join("\n")}
  TEXT

  RandallCommands.new(event).send(command, args)
end

class RandallCommands
  attr_reader :event

  @@public_commands = []
  @@commands = []

  def self.public_command(*args, symbol)
    @@public_commands << [symbol, *args].join(" ")
    command(*args, symbol)
  end

  def self.command(*args, symbol)
    @@commands << [symbol, *args].join(" ")
  end

  def self.available_commands(role)
    return commands if role == :admin

    @@public_commands
  end

  def self.commands
    @@commands
  end

  def initialize(event)
    @event = event
  end

  public_command def rankings(args)
    results = "Rankings:\n"

    last_score = 0
    last_ranking = 0
    Player.where('points > 0').order('points DESC').each_with_index do |player, index|
      rank = index

      if player.points == last_score
        rank = last_ranking
      else
        last_ranking = rank
      end

      results += "##{rank + 1} - #{player.name} (#{player.points} points)\n"

      last_score = player.points
    end

    print_slowly(results)
  end


  public_command def tournaments(args)
    results = "Recently recorded tournaments:\n"

    Tournament.order('created_at DESC').each_with_index do |tournament|
      results += "• #{tournament.name} (#{tournament.url} - id: #{tournament.slug})\n"
    end

    event.respond(results)
  end

  public_command def flip(args)
    result = rand(2)

    if result == 0
      event.respond("Heads!")
    else
      event.respond("Tails!")
    end
  end

  public_command def random(args)
    event.respond(SMASH_ULTIMATE_CHARACTERS.sample)
  end

  command(def submit(args)
    bracket_url = args.first

    begin
      summary = RecordTournamentResults.new(bracket_url: bracket_url).call
      event.respond("Recorded results!")
      print_slowly(summary)
    rescue InvalidTournamentURLException => e
      event.respond("I couldn't figure out that tournament url sorry! It should be something like https://www.start.gg/tournament/love-to-see-it-respawn-fundraiser/details")
    rescue InvalidResponseException => e
      event.respond("Hmmm, I can't seem to talk to start.gg right now.")
    rescue AlreadyRecordedTournamentException => e
      event.respond("We've already recorded that tournament before!")
    end
  end)

  command(def forget(args)
    slug = args.first

    ForgetTournamentResults.new(slug: slug).call

    event.respond("Forgot all about it!")
  end)

  private

  def print_slowly(message)
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
end

# This method call has to be put at the end of your script, it is what makes the bot actually connect to Discord. If you
# leave it out (try it!) the script will simply stop and the bot will not appear online.
bot.run
