require "capybara"
require "capybara/dsl"
require "capybara/webkit"

Capybara.configure do |config|
  config.run_server     = false
  config.default_driver = :webkit
  config.app_host       = "http://nysdoccslookup.doccs.ny.gov"
end

class Scrape
  include Capybara::DSL

  def get_data
    visit "/"
    fill_in "M00_DIN_FLD1I", :with => "12"
    fill_in "M00_DIN_FLD2I", :with => "A"
    fill_in "M00_DIN_FLD3I", :with => "0001"
    click_button "Submit"    
    
    puts page.find("#content").text
  end
end

scraper = Scrape.new
scraper.get_data
