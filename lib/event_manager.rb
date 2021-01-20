require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"
require "time"

def clean_zipcode(zipcode)
=begin
  if zipcode.nil?
    "00000"
  elsif zipcode.length < 5
    zipcode.rjust(5,"0")
  elsif zipcode.length > 5
    zipcode[0..4]
  else
    zipcode
  end
=end
  #same above, but clean
  zipcode.to_s.rjust(5, "0")[0..4] 
end

def clean_phonenumber(phonenumber)
  phonenumber = phonenumber.to_s.strip.gsub(/[^0-9]/, "") 

  if phonenumber.length < 10
    "#{phonenumber} is an invalid phone number! Phone number must have 10 numbers"
  elsif phonenumber.length == 11
    if phonenumber[0] == "1"
      phonenumber[1..10]
    else
      "#{phonenumber} is an invalid phone number! Bigger than 10 and the first is not 1"
    end
  elsif phonenumber.length > 11
    "#{phonenumber} have more than 11 numbers. Invalid number!!"
  else
    phonenumber
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"],
    ).officials
  rescue
    puts "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts form_letter
  end
end

#start
puts ""
puts "EventManager initialized."
puts ""

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
day_hour_array = Array.new
weekday_array = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  date_time = row[:regdate]
  time_format = "%m/%d/%Y %H:%M"
  weekNames = { 0 => "sunday", 1 => "monday", 2 => "tuesday", 3 => "wednesday", 4 => "thursday", 5 => "friday", 6 => "saturday" }

  puts "Creating answer for name #{name}, ID=#{id}:"

  zipcode = clean_zipcode(row[:zipcode])
  phonenumber = clean_phonenumber(row[:homephone])

  date = DateTime.strptime(date_time, time_format)
  weekday = weekNames[date.wday]

  weekday_array.push(weekday)
  day_hour_array.push(date.hour)

  puts "phone: #{phonenumber}"
  puts date_time  
  puts "Weekday: #{weekday}"

  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  puts "Answer created!"
  puts ""
end

puts "Hour of the day that most people registered: #{day_hour_array.max_by { |a| day_hour_array.count(a) }}h"
puts "Day of the week that most people registered: #{weekday_array.max_by { |a| weekday_array.count(a) }}"
