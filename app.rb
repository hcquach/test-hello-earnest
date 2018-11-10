require 'watir'
require 'open-uri'
require_relative 'database'
# require 'pry-byebug' # uncomment for debug

# Creating the instance of browser to navigate to Airbnb
browser = Watir::Browser.new :chrome
browser.goto('https://www.airbnb.fr')

# Load the saved browser session cookies for authentication
file = File.open('cookies.txt')
content = file.gets
if !content.nil?
  raw_line = content.split("@_@")
  raw_line.each do |line|
    cookie = JSON.parse(line)
    browser.driver.manage.add_cookie(:name => cookie["name"], :value => cookie["value"])
  end
end

# Iterate through the flats
FLATS.each do |flat|
  # Create the flat and host url
  flat_page_url = "https://www.airbnb.fr/rooms/#{flat[:flat_id]}?check_in=#{flat[:checkin]}&guests=1&adults=1&check_out=#{flat[:checkout]}"
  host_page_url = "https://www.airbnb.fr/contact_host/#{flat[:flat_id]}?check_in=#{flat[:checkin]}&guests=1&adults=1&check_out=#{flat[:checkout]}"
  # Retrieve description, host and total price
  browser.goto(flat_page_url)
  description = browser.h1.wait_until(&:present?).text
  host = browser.element(:id => "host-profile").h2.wait_until(&:present?).text[7..-1]
  # Rescue when total_price doesn't exist
  begin
    total_price = browser.elements(:class => "_1spn3flr")[1].text.split(" ").join.to_i
  rescue
    total_price = 0
  end

  # Test the presence of total_price and send a message only if existing
  if total_price == 0
    puts "#{description} is unavailable for those dates"
  else
    # Prepare and send message to host
    browser.goto(host_page_url)
    browser.wait
    # Test if redirection to authenticate and give a timer to authenticate
    until browser.url == host_page_url
      p "Please authenticate and try again"
      sleep(20)
      browser.goto(host_page_url)
      browser.wait
    end
    # Create the message and send to host
    message = "Hello #{host},\nYour housing #{description} is of interest to me.\nWould you accept a price of #{(total_price/(1.4)).to_i} euros (including nights and household expenses) excluding service charges and tourist taxes?\nThank you for your answer, see you soon!"
    button_send_message = browser.buttons.last
    browser.element.textarea(:id => "homes-contact-host--message-textarea").set(message)
    # button_send_message.click # uncomment to send message
    # p "Message sent to #{host}"
  end
end

# Save browser session cookies for authentication
file = File.open('cookies.txt', "wb")
browser.driver.manage.all_cookies.each do |cookie|
    file.write(cookie.to_json)
    file.write("@_@")
end
