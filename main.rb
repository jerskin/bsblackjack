#TODO: fix out of bankroll bug, split, double, insurance, surrender, dealer blackjack

require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_STAND_AMOUNT = 17
INITIAL_BANKROLL = 500

helpers do
  def get_card_image(card)
    rank = card[0]
    suit = card[1]

    "<img src='/images/cards/#{rank}#{suit}.png' height='9%' width='9%'>"
  end

  def calculate_hand_total(cards)
    total = 0
    card_ranks = cards.map{ |card| card[0] }

    card_ranks.each do |rank|
      if ['K', 'Q', 'J'].include? rank
        total += 10
      elsif rank == 'A'
        total += 11
      else
        total += rank.to_i
      end   
    end

    card_ranks.select{ |rank| rank == 'A' }.count.times do
      total -= 10 if total > 21
    end
    return total
  end

  def player_wins(message)
    if @player_has_blackjack == true
      session[:player_winnings] = (session[:player_winnings]*1.50).to_i
      session[:player_bankroll] += session[:player_winnings].to_i
    else
      session[:player_bankroll] += session[:player_winnings].to_i
    end

    @show_play_again = true
    @show_hit_and_stay = false
    @hide_dealer_card = false
    @win_alert = "#{message} <strong>*** WIN $#{session[:player_winnings]} *** Bankroll: $#{session[:player_bankroll]}</strong>"
  end

  def player_loses(message)
    session[:player_bankroll] -= session[:player_winnings]
    @show_play_again = true
    @show_hit_and_stay = false
    @hide_dealer_card = false
    @loss_alert = "#{message} <strong>--- LOSE $#{session[:player_winnings]} --- Bankroll: $#{session[:player_bankroll]}</strong>"
  end

  def player_ties(message)
    @show_play_again = true
    @show_hit_and_stay = false
    @hide_dealer_card = false
    @push_alert = "#{message} <strong>=== PUSH === Bankroll: $#{session[:player_bankroll]}</strong>"
  end
end

before do
  @show_hit_and_stay = true
  @hide_dealer_card = true
end

get '/' do
  if session[:username]
    redirect '/bet'
  else
    redirect '/set_username'
  end
end

get '/set_username' do
  session[:player_bankroll] = INITIAL_BANKROLL
  erb :set_username
end

post '/set_username' do
  if params[:username].empty? || params[:username].nil?
    @error = "No name was entered.  Please enter a name to play."
    halt erb :set_username
  end

  session[:username] = params[:username]
  redirect '/bet'
end

get '/bet' do
  if session[:player_bankroll] <= 0
    @error = "Looks like you're out of cash...but you can always start a new game."
    halt erb(:game_over)
  end

  session[:player_bet] = nil
  session[:player_winnings] = nil
  erb :bet
end

post '/bet' do
  if params[:bet].nil? || params[:bet].to_i == 0
    @error = "You must enter a bet amount."
    halt erb(:bet)
  elsif params[:bet].to_i > session[:player_bankroll]
    @error = "You entered a bet amount that exceeded your bankroll.  You may only bet up to $#{session[:player_bankroll]}."
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet].to_i
    @show_hit_and_stay = true
    redirect '/game'
  end
end

get '/game' do
  if session[:player_bankroll] <= 0
    @error = "Looks like you're out of cash...but you can always start a new game."
    halt erb(:game_over)
  elsif session[:player_bankroll] < session[:player_bet]
    @error = "You entered a bet amount that exceeded your bankroll.  You may only bet up to $#{session[:player_bankroll]}."
    halt erb(:bet)
  end

  @hide_dealer_card = true
  session[:player_winnings] = session[:player_bet]
  # create a deck and put it in session
  card_rank = ['A','K','Q','J','10','9','8','7','6','5','4','3','2']
  card_suit = ['s','h','c','d']

  session[:deck] = []
  card_rank.each do |rank|
    card_suit.each do |suit|
      session[:deck] << [rank, suit]
    end
  end

  session[:deck].shuffle!

  session[:player_hand] = []
  @player_has_blackjack = false
  session[:dealer_hand] = []

  2.times do
    session[:player_hand] << session[:deck].pop
    session[:dealer_hand] << session[:deck].pop
  end

  player_hand_total = calculate_hand_total(session[:player_hand])
  dealer_hand_total = calculate_hand_total(session[:dealer_hand])

  #initial check for BJ for both dealer and player
  if player_hand_total == BLACKJACK_AMOUNT && dealer_hand_total == BLACKJACK_AMOUNT
    player_ties("Both #{session[:username]} and the dealer have Blackjack")
  elsif player_hand_total == BLACKJACK_AMOUNT
    @player_has_blackjack = true
    player_wins("#{session[:username]} has Blackjack!")
  elsif dealer_hand_total == BLACKJACK_AMOUNT
    player_loses("Dealer has Blackjack")
  end

  erb :game

end

get '/game/player_hit' do
  session[:player_hand] << session[:deck].pop

  player_hand_total = calculate_hand_total(session[:player_hand])
  
  if player_hand_total > BLACKJACK_AMOUNT
      player_loses("Busted!")
  end

  if player_hand_total == BLACKJACK_AMOUNT
    redirect '/game/dealer'
  end

  erb :game
end

get '/game/player_stay' do
  redirect '/game/dealer'
end

get '/game/player_double' do
  session[:player_hand] << session[:deck].pop
  session[:player_winnings] *= 2
  player_hand_total = calculate_hand_total(session[:player_hand])
  
  if player_hand_total > BLACKJACK_AMOUNT
    player_loses("Busted!")
    erb :game
  else
    redirect '/game/dealer'
  end
end

get '/game/dealer' do
  @show_hit_and_stay = false
  @hide_dealer_card = false

  dealer_hand_total = calculate_hand_total(session[:dealer_hand])

  while dealer_hand_total < DEALER_STAND_AMOUNT
    session[:dealer_hand] << session[:deck].pop
    dealer_hand_total = calculate_hand_total(session[:dealer_hand])
  end

  if dealer_hand_total > BLACKJACK_AMOUNT
    player_wins("Dealer busted!")
  else dealer_hand_total >= DEALER_STAND_AMOUNT
    redirect '/game/results'
  end

  erb :game
end

get '/game/results' do
  @show_hit_and_stay = false
  @hide_dealer_card = false

  player_hand_total = calculate_hand_total(session[:player_hand])
  dealer_hand_total = calculate_hand_total(session[:dealer_hand])

  if player_hand_total < dealer_hand_total
    player_loses("#{session[:username]} has #{player_hand_total}, while the dealer has #{dealer_hand_total}")
  elsif player_hand_total > dealer_hand_total
    player_wins("#{session[:username]} has #{player_hand_total}, while the dealer has #{dealer_hand_total}")
  else
    player_ties("Both #{session[:username]} and the dealer have #{player_hand_total}")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end


