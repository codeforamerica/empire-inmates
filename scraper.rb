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
  
  def go
    (0..100).each do |number|
      puts get_prisoner_by_din("12", "A", number.to_s.rjust(4, "0"))
      sleep(30)
    end
  end

  # Gets a hash of prisoner info given an DIN.
  # http://www.doccs.ny.gov/univinq/fpmsdoc.htm#din
  def get_prisoner_by_din(year, letter, sequence)
    visit "/"
    fill_in "M00_DIN_FLD1I", :with => year.to_s
    fill_in "M00_DIN_FLD2I", :with => letter.to_s
    fill_in "M00_DIN_FLD3I", :with => sequence.to_s
    click_button "Submit"    
    
    # Did we hit an error page?
    errors = page.all("p.err")
    if errors.size > 0
      puts errors.map { |x| x.text }.join(", ")
      return
    end
    
    store = {} # A hash of data.

    tables = page.find("#content").all("table")

    # ID + Location info
    store.merge!(Hash[tables[0].all("th").map { |x| x.text }.zip(tables[0].all("td").map { |x| x.text })])

    # Sentence Terms and Release Dates
    store.merge!(Hash[tables[2].all("th").map { |x| x.text }.zip(tables[2].all("td").map { |x| x.text })])

    # Crimes of Conviction
    crimes = { "crimes" => {} }
    crimes["crimes"] = Hash[tables[1].all("td[headers=crime]").map { |x| x.text }.zip(tables[1].all("td[headers=class]").map { |x| x.text })]
    store.merge!(crimes)  
      
    store
  end
end

Scrape.new.go
