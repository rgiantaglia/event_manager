require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
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

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exists?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def clean_phone_number(phone_number)
    phone_number = phone_number.to_s.gsub(/[^0-9A-Za-z]/, '')
    if phone_number.length == 10 or (phone_number.length == 11 and phone_number.chr == "1")
        phone_number = phone_number[-10..-1]
    else
        phone_number = ""
    end
    phone_number
end


def clean_time(time)
    Time.strptime(time, "%D %R").hour
end

def clean_date(date)
    Time.strptime(date, "%D %R").wday
end

def time_targeting(registrations)
    registrations = registrations.sort.tally
    registrations = registrations.select {|k,v| v == registrations.values.max}
    registrations = registrations.keys.join(", ")
    puts "The peak hours were: #{registrations}."
end

times = []

def day_targeting(registrations)
    registrations = registrations.sort.tally
    registrations = registrations.select {|k,v| v == registrations.values.max}
    registrations = Date::DAYNAMES[registrations.keys.first]
    puts "The day of the week with most registrations was #{registrations}."
end

dates = []

puts "Event Manager Initialized!"

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    times << clean_time(row[:regdate])
    dates << clean_date(row[:regdate])
    phone_number = clean_phone_number(row[:homephone])
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id,form_letter)

end

time_targeting(times)

day_targeting(dates)
