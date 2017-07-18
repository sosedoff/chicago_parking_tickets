require "capybara"
require "capybara/dsl"
require "capybara/poltergeist"

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, { js_errors: false })
end
Capybara.default_driver = :poltergeist

class Paybot
  include Capybara::DSL

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def run
    # Entry point URL where all the tickets are listed
    tickets_url = sprintf(
      "https://parkingtickets.cityofchicago.org/CPSWeb/retrieveTicketsByLicensePlate.do?plateNumber=%s&plateState=%s&plateType=%s&plateOwnerName=%s",
      config[:plate], config[:state], config[:type], config[:name]
    )

    # First step is to figure out which tickets are not paid
    visit tickets_url

    # Check if we have any tickets
    if !has_button?("Continue")
      puts "Looks like we dont have any tickets!"
      return
    end

    # Mark all tickets that we want to pay. ALL OF THEM
    within ".ticketList" do
      all("input[type='checkbox']").each { |el| el.click }
    end
    click_button "Continue"

    # Select payment method. CC is a default
    click_button "Next"

    # Confirm payment method and amount
    click_button "Next"

    # Fill in card details
    within "#creditCardForm" do
      find("#cardType").select(config[:card_type])
      find("#cardNumber").set(config[:card_number])
      find("#expirationMonth").select(config[:card_exp_month])
      find("#expirationYear").select(config[:card_exp_year])
      find("#cvv").set(config[:card_cvv])
      find("#name").set(config[:card_name])
      find("#address").set(config[:card_address])
      find("#city").set(config[:card_city])
      find("#state").select(config[:card_state])
      find("#zip").set(config[:card_zip])
    end
    click_button "Next"

    # Authorize the payment
    click_button "Submit Payment"
  end
end