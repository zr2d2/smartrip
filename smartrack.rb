require 'selenium-webdriver'
require 'crack'
require 'net/http'

@xml_urls = []
@devices = 'IE 11'
@urls = []
login_page = 'https://smartrip.wmata.com/Account/AccountLogin.aspx?'

@driver = Selenium::WebDriver.for :firefox
@driver.navigate.to login_page
user_name_field = @driver.find_element(:css, 'input#ctl00_MainContent_txtUsername')
user_name_field.send_keys 'zr2d2'

password_field = @driver.find_element(:css, 'input#ctl00_MainContent_txtUsername')
password_field.send_keys 'ycTm&LI%q21e'

for i in (0..@urls.length-1)
  puts "#{@urls[i]}"


  @driver.navigate.to "http://www.webpagetest.org/"

  sleep 1
  if i == 0 then
    if @driver.find_element(:css, 'input#ctl00_MainContent_txtUsername').displayed? then
      puts 'Advanced tab already displayed'
    else
      url_element = @driver.find_element(:css, '#advanced_settings').click
    end
  end
  sleep 1

  if @driver.find_element(:css, '#url').displayed? then
    url_element = @driver.find_element(:css, '#url')
  else
    puts "Cannot find #url element!"
  end

  url_element.send_keys "#{@urls[i]}"
  puts "looking for test numbers for #{@devices}"
  input_browser_type = @driver.find_element(:name, 'browser')
  input_browser_type.send_keys "#{@devices}"

  input_runs = @driver.find_element(:css, 'input#number_of_tests')
  puts "attempting to clear"
  input_runs.clear()
  puts "attempting to send"
  input_runs.send_keys('1')

  puts 'looking for submit button'
  button = @driver.find_element(:name, 'submit').click
  sleep 2

  print "result url: " + @driver.current_url + "\n"
  @resulting_url = @driver.current_url
  @xml_url = @driver.current_url.gsub("result", "xmlResult").to_s.chomp
  @xml_urls << @xml_url
end

@driver.quit
#Start using Crack

uri = URI.parse(URI.encode(@xml_url))
response = Net::HTTP.get(URI(uri))
parsed_res = Crack::XML.parse(response)
status = parsed_res["response"]["statusCode"]
puts "status: " + status

until (status.to_i == 200) do
  puts "Status Code on getting xmlResult is: #{status.to_s}"
  puts "Sleeping for 10 seconds"
  sleep 10

  uri = URI.parse(URI.encode(@xml_url))
  response = Net::HTTP.get(URI(uri))
  parsed_res = Crack::XML.parse(response)
  status = parsed_res["response"]["statusCode"]
end

@median_TTFB = (parsed_res["response"]["data"]["median"]["firstView"]["TTFB"])
puts "median TTFB: #{@median_TTFB}"

puts "Sending email notification!"
@emailSubject = "Selenium Web Page Test Complete"
`echo "I just made a scraper!" | mailx -s  "#{@emailSubject}" -F "Zach - WEBPAGETEST COMPLETE" -f zrowe007@gmail.com`



















