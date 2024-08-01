require 'csv'
require 'time'
require 'date'
require 'google/apis/civicinfo_v2'
require 'erb'

puts 'Event Manager Initialized!'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


def clean_phone_number(home_phone)
  home_phone = home_phone.tr('^A-Za-z0-9',"")
# if phone number is 10 digits it is good
  if home_phone.length == 10
      home_phone
# elsif phone length is 11 and 1st digit is 1 truncate leading one and phone number is good
  elsif home_phone.length == 11 && home_phone[0] == "1"
      home_phone.slice(1,10)
    else 
        "0000000000"
  end
end

def hours_vs_registration(registration_hour)
  registration_hour.reduce(Hash.new(0)) do |result, value|
  result[value] += 1
  result
  end
end

def day_of_week(registration_day)
    registration_day.reduce(Hash.new(0)) do |result, value|
    result[value] += 1
    result
    end
  end



  contents = CSV.open('event_attendees.csv', 
headers: true,
header_converters: :symbol
)
registration_hour = []
registration_day = []
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter


contents.each do |row|
  id = row[0]
zipcode = row[:zipcode]
name = row[:first_name]
home_phone = row[:homephone]
registration_date = row[:regdate]
legislators = legislators_by_zipcode(zipcode)

form_letter = erb_template.result(binding)

save_thank_you_letter(id,form_letter)

registration_hour = registration_hour.push(Time.strptime(registration_date, "%y/%d/%m %k:%M").hour.to_s)
registration_day = registration_day.push(Date::DAYNAMES[Date.strptime(registration_date, "%y/%d/%m").wday])


phone_number = clean_phone_number(home_phone)
puts "clean phone numbers are #{phone_number}"
# zipcode = clean_zipcode(zipcode)
end
puts "Hours of Registration are as: #{hours_vs_registration(registration_hour).sort_by{|_key, value| -value}.to_h}"

day = 
  puts "Days with most user registrationday are \n #{day_of_week(registration_day).sort_by{|_key, value| -value}.to_h}"