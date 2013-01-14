#!/usr/bin/env ruby
require 'open-uri'
require 'json'
require 'chronic'

ACCOUNT = ARGV[0]
AUTH_TOKEN = ARGV[1]
PROJECT_ID = ARGV[2]

def fetch_deploys(page = 1)
  result = open(
    "http://#{ACCOUNT}.airbrake.io/projects/#{PROJECT_ID}/deploys.json?auth_token=#{AUTH_TOKEN}&page=#{page}"
  ).read

  JSON.parse(result)['deploys'].map { |deploy|
    { date: Time.parse(deploy['created_at']).getlocal,
      sha: deploy['scm_revision'] }
  }
end


def find_deploy_date(sha)
  fetch_deploys.each do |deploy|
    result = `git log #{sha}..#{deploy[:sha]}`
    if result.match /path not in working tree/
      # nothing
    else
      puts "deployed on #{deploy[:date].strftime('%e %b %Y %H:%m:%S%p')}"
      exit
    end
  end

  # TODO
  # uh oh, if it wasn't found then we still have tons of other pages of deploys
  # to search through!
end

def list_deploys_on_date(date)
  deploys = deploys_on_date(date)
  if deploys.empty?
    puts "No deploys on that date"
  else
    puts "Head of last deploy on date"
    puts deploys[:last_deploy]
    puts "Head of most recent previous deploy before date"
    puts deploys[:most_recent_previous_deploy]
  end
end

def last_deploy_on_date(date)
  page = 1
  result = {}

  # starting at page 1
  # get the list of deploys, the first one that was on the given date is our "last deploy of day"
  # do
  #  result = fetch_deploys(page)
  # while result.last[:date] > date

  result.find do |result|
    result[:date].to_date == date.to_date
  end
end

def deploys_on_date(date)
  initial_deploy = last_deploy_on_date(date)
  previous_deploy = first_deploy_on_date(date - 1)

  # keep going through pages until the first deploy after this, not on that day is found
end

command_flag = ARGV[3]
option = ARGV[4]

if command_flag == '-sha'
 find_deploy_date(option)
elsif command_flag == '-date'
  list_deploys_on_date(Chronic.parse(option))
else
  puts "Invalid command '#{command_flag}'"
end

# deploy_tracker -sha dsfjkdsfjkdsf
# deploy_tracker -date yesterday
# deploy_tracker -date jan 1st
