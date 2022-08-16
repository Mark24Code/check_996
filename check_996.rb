#!/usr/bin/env ruby

require 'time'
require 'date'

DAY_BEGIN = '00:00:00'
DAY_END   = '23:59:59'

class String
  def blue
    return "\033[34m #{self}\033[0m"
  end
  def red
    return "\033[31m #{self}\033[0m"
  end
  def green
    return "\033[32m #{self}\033[0m"
  end
  def yellow
    return "\033[33m #{self}\033[0m"
  end
  def magenta
    return "\033[35m #{self}\033[0m"
  end
  def cyan
    return "\033[36m #{self}\033[0m"
  end
end

class GitCounter
  def initialize(opts={})
    @start_time = opts.fetch(:start_time, '10:00:00')
    @end_time = opts.fetch(:end_time, '18:00:00')

    @commits = []

    @day_grouping = {}

    @overtime_count = 0
    @overtime_begin = []
    @overtime_end   = []
  end

  def get_git_commit_dates
    date_pattern = /Date:(.*)/

    history = `git log --date=unix | cat`
    raw_commits = history.split("\n\n")

    raw_commits.each do |c|
      if date_pattern.match(c)
        @commits.push Time.at($1.strip.to_i)
      end
    end
  end

  def day_grouping(commit_time)
    work_day = Time.parse(DAY_BEGIN,commit_time)
    @day_grouping[work_day] ||= []
    @day_grouping[work_day].push(commit_time)
  end

  def grouping_commits
    @commits.each do |c|
      day_grouping(c)
    end
  end

  def calc_overtime
    work_days = @day_grouping.keys
    work_days.each do | work_day|
      this_day_commits = @day_grouping[work_day]

      job_start_time = Time.parse(@start_time, work_day)
      job_end_time = Time.parse(@end_time, work_day)

      this_day_commits.each do | one_commit_time |
        if one_commit_time < job_start_time 
          @overtime_count += 1
          @overtime_begin << one_commit_time
        end

        if one_commit_time > job_end_time
          @overtime_count += 1
          @overtime_end << one_commit_time
        end
      end 
    end
  end

  def sort_overtime_range(time_arr)
    result = time_arr.map { |t| t.strftime("%T") }
    result.sort!
  end

  def icu_996_report(percent)

    label = "JobHeath(996ICU): "
    result = nil
    if percent <= 5
      result = "😄" + "\tyou got good job!".green

    end
    if percent > 5 && percent < 30
      result = "😑" + "\temmm... you maybe tired a lot.".yellow
    end
  
    if percent >= 30 && percent < 60
      result = "😰" + "\tBad! Amost 30% ~ 60% time overtime, you need change it!".red
    end

    if percent >= 60
      result = "😡" + "\tFuck the job".magenta
    end

    puts label
    puts result
  end

  def report
    report_title = "=" * 8 + " Report " + "=" * 8
    puts report_title.cyan
    puts "You expected worktime: " + "#{@start_time} ~ #{@end_time}".green
    puts ""
    puts "Tips:"
    puts "Not your work time? You can change by `check_996 -s 10:00 -e 18:00`"
    puts "more detail: `check_996 -h`"
    puts ""
    overtime_percent = (@overtime_count * 1.0 / @commits.length * 100.0).ceil(1)
    puts "Overtime Percent: " + "#{overtime_percent}%".yellow
    puts ""
    puts "Repo larliest working time top3 (24h):"
    begin_time_range = sort_overtime_range(@overtime_begin)
    top3 = begin_time_range[..2]

    if top3 && top3.length > 0
      top3.each do |et|
        puts et.red
      end
    else
      puts "no data".cyan
    end
    puts ""
    puts "Repo latest working time top3 (24h):"
    end_time_range = sort_overtime_range(@overtime_end)
    bottom3 = end_time_range[-3..]
    if bottom3 && bottom3.length > 0
        bottom3.each do |et|
        puts et.red
      end
    else
      puts "no data".cyan
    end
    puts ""
    icu_996_report(overtime_percent)
  end

  def run
    get_git_commit_dates
    grouping_commits
    calc_overtime
    report
  end
end

require 'optparse'

def format_time(raw_time)
  range_time = raw_time.strip

  if range_time.include? ":"

  end
  return ts
end

def validator(text)
  pattern = /\d\d:\d\d(:\d\d)?/
  if !pattern.match(text)
    puts "invalid: " + "#{text}".yellow
    puts "-s / -e format must 24h string  e.g. 10:00:00 or 10:00  "
    exit 0
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: count_code.rb [options]"

  opts.on("-s", "--start [TIME]", "start job time e.g. 10:00:00") do |t|
    validator(t)
    options[:start_time] = t
  end
  opts.on("-e", "--end [TIME]", "end job time  e.g. 18:00:00") do |t|
    validator(t)
    options[:end_time] = t
  end
  opts.on("-v", "--version", "version") do
    puts "Check996 v1.0.0"
    puts ""
    puts "author: Mark24Code"
    puts "repo: https://github.com/Mark24Code/check_996"
    exit 0
  end
end.parse!


GitCounter.new(options).run