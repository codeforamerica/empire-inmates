require "capybara"
require "capybara/dsl"

Capybara.configure do |config|
  config.run_server        = false
  config.default_driver    = :selenium
  config.javascript_driver = :selenium
  config.app_host          = "http://nysdoccslookup.doccs.ny.gov"
end

class Scrape
  include Capybara::DSL

  class ContentError < StandardError; end

  def go
    (0..100).each do |number|
      begin
        puts(get_prisoner_by_din("12", "A", number.to_s.rjust(4, "0")).inspect)
      rescue ContentError => error
        puts "Hit an error, check the inspected exception:"
        puts error.inspect
      end
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
    error = page.all("p.err").first
    raise ContentError, error.text if error.text.length > 0
    
    store = {} # A hash of data.

    tables = page.find("#content").all("table")
    puts tables.inspect

    # ID + Location info
    store.merge!(Hash[tables[0].all("th").map { |x| x.text }.zip(tables[0].all("td").map { |x| x.text })])

    # Sentence Terms and Release Dates
    store.merge!(Hash[tables[2].all("th").map { |x| x.text }.zip(tables[2].all("td").map { |x| x.text })])

    # Crimes of Conviction
    crimes = { "crimes" => {} }
    crimes["crimes"] = Hash[tables[1].all("td[headers=crime]").map { |x| x.text }.zip(tables[1].all("td[headers=class]").map { |x| x.text })]
    store.merge!(crimes)  
      
    return store
  end
end

Scrape.new.go
