require "capybara"
require "capybara/dsl"
require "json"
require "sequel"
require "pg"

COLUMNS = ["DIN (Department Identification Number)", "Inmate Name", "Sex", "Date of Birth", "Race / Ethnicity", "Custody Status", "Housing / Releasing Facility", "Date Received (Original)", "Date Received (Current)", "Admission Type", "County of Commitment", "Latest Release Date / Type (Released Inmates Only)", "Aggregate Minimum Sentence", "Aggregate Maximum Sentence", "Earliest Release Date", "Earliest Release Type", "Parole Hearing Date", "Parole Hearing Type", "Parole Eligibility Date", "Conditional Release Date", "Maximum Expiration Date", "Maximum Expiration Date for Parole Supervision", "Post Release Supervision Maximum Expiration Date", "Parole Board Discharge Date", "crimes"]

Capybara.configure do |config|
  config.run_server        = false
  config.default_driver    = :selenium
  config.javascript_driver = :selenium
  config.app_host          = "http://nysdoccslookup.doccs.ny.gov"
end

# Use an environment variable if defaults aren't good enough or for convenience if we're running
# on Heroku.
db_url = ENV['DATABASE_URL'] || "postgres://cfanyc:cfanyc@localhost:5432/inmate_data"
DB = Sequel.connect(db_url)

DB.create_table? :inmates do
  column :din, String
  column :name, String
  column :sex, String
  column :dob, String
  column :race, String
  column :custody_status, String
  column :facility, String
  column :original_date_received, String
  column :current_date_received, String
  
end

class Scrape
  include Capybara::DSL

  class ContentError < StandardError; end
  
  attr_accessor :inmates

  def initialize
    self.inmates = DB[:inmates]
  end

  def go
    (101..500).each do |number|
      begin
        inmate = get_prisoner_by_din("12", "A", number.to_s.rjust(4, "0"))
        puts self.inmates.insert(inmate.values)
        # rescue ContentError => error
      rescue StandardError => error
        # puts "Hit an error, check the inspected exception:"
        # puts error.inspect
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
