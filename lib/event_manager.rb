require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

WEEKDAYS = %w[Sun Mon Tue Wed Thu Fri Sat].freeze
def maximum(hash)
  sorted_hash = hash.sort_by(&:last).reverse
  sorted_hash.take_while { |element| element.last == sorted_hash.first.last }.to_h
end

def count_days(data)
  counter = Hash.new(0)
  data.each do |row|
    register_day = Date.strptime(row[:regdate], '%D %R').wday
    counter[WEEKDAYS[register_day]] += 1
  end
  maximum(counter)
end

def count_hours(data)
  counter = Hash.new(0)
  data.each do |row|
    register_hour = Time.strptime(row[:regdate], '%D %R').hour
    counter[register_hour] += 1
  end
  maximum(counter)
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number = number.to_s.chars.select { |char| ('0'..'9').include?(char) }.join
  if number.length == 10
    number
  elsif number.length == 11 && number.start_with?('1')
    number[1..10]
  else
    '0000000000'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = clean_zipcode(row[:zipcode])
#   legislators = legislators_by_zipcode(zipcode)

#   form_letter = erb_template.result(binding)

#   save_thank_you_letter(id, form_letter)
# end

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
  print "#{id} #{name} #{phone_number}\n"
end

# p count_days(contents)
# p count_hours(contents)
