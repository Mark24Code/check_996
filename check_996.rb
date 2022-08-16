#!/usr/bin/env ruby

require 'time'
require 'date'

DAY_BEGIN = '00:00:00'
DAY_END   = '23:59:59'

VERSION = "1.0.0"
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
    @start_time = opts.fetch(:start_time, '10:30:00')
    @end_time = opts.fetch(:end_time, '19:30:00')

    @range = opts.fetch(:range, nil)
    @git_log = opts.fetch(:git_log, nil) || 'git log --all'


    @commits = []

    @day_grouping = {}

    @overtime_count = 0
    @overtime_begin = []
    @overtime_end   = []
  end

  def get_git_commit_dates
    date_pattern = /Date:(.*)/

    history = `#{@git_log} --date=unix | cat`
    raw_commits = history.split("\n\n")

    raw_commits.each do |c|
      if date_pattern.match(c)
        @commits.push Time.at($1.strip.to_i)
      end
    end

    # filter
    if @range && @range.length == 2

      range_start_time, range_end_time = @range
      unix_start = range_start_time.to_time
      unix_end = range_end_time.to_time

      @commits = @commits.select do |c|
        return c >= unix_start && c <= unix_end
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
    report_title = "=" * 8 + " Check 996 Report " + "=" * 8
    puts report_title.cyan
    puts "You expected worktime: " + "#{@start_time} ~ #{@end_time}".green

    if @range && @range.length == 2
      range_start_time, range_end_time = @range
      puts ""
      puts "Commits time range:"
      puts ""
      time_range_str = range_start_time.to_time.to_s + ' ~ ' + range_end_time.to_s
      puts time_range_str.cyan
    else
      puts ""
      puts "Commits time range:"
      puts ""
      puts "all commit history".cyan
      puts ""
    end

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

def invalid_param(i, msg = nil)
  puts "invalid: " + "#{i}".yellow
  if msg
    puts "tips:".cyan + msg
  end
end

def time_range_gen(time_type, time_count)
  end_time = Time.now
  
  if time_type == 'day'
    start_time = Date.today - time_count
    end_time = Date.today
  end

  if time_type == 'week'
    start_time = Date.today - time_count * 7
  end

  if time_type == 'month'
    start_time = Date.today - time_count * 30
  end

  if time_type == 'year'
    start_time = Date.today - time_count * 365
  end

  if time_type == 'range'
    start_time, end_time = time_count
  end

  return [start_time, end_time]
end

def then_quit
  exit 0
end

def validator_range(text)
  text = text.strip

  case text
  when 'last_day'
    return time_range_gen('day', 1)
  when 'last_week'
    return time_range_gen('week', 1)
  when 'last_month'
    return time_range_gen('month', 1)
  when 'last_year'
    return time_range_gen('year', 1)
  when /last_(\d*)_(day|week|month|year)/
    time_count = nil
    if $1.to_i < 0
      invalid_param(text, "#{$2} number should > 0")
      then_quit
    end

    if $1.to_i == 0
      puts "#{text} -> will use `last_#{$2}`"
      time_range_gen($2, 1)
    end

    time_count = $1.to_i
    return time_range_gen($2, time_count)
  when /(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}),(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/
    ft = "%Y-%m-%d %T"
    range_start_time_catch = $1
    range_end_time_catch = $2
    range_start_time = DateTime.strptime(range_start_time_catch,ft)
    range_end_time = DateTime.strptime(range_end_time_catch,ft)
    if range_start_time >= range_end_time
      invalid_param(text, "time range order wrong. start_time < end_time")
      then_quit
    end
    return time_range_gen('range', [range_start_time, range_end_time])

  else
    puts "check your -f params, more details `-h`".yellow
    then_quit
  end
end

def validator_gitlog(text)
  pattern = /git log .*/
  if !pattern.match(text)
    puts "invalid: " + "#{text}".yellow
    puts "should be: git log .... "
    exit 0
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: count_code.rb [options]"

  opts.on("-s WORK_START_TIME", "--start WORK_START_TIME", "start job time e.g. 10:00:00") do |t|
    validator(t)
    options[:start_time] = t
  end
  opts.on("-e WORK_END_TIME", "--end WORK_END_TIME", "end job time  e.g. 18:00:00") do |t|
    validator(t)
    options[:end_time] = t
  end

  opts.on("-g GIT_LOG_CMD", "--git-log GIT_LOG_CMD", "use git log command, default is `git log --all`") do |t|
    if t
      validator_gitlog(t)
      options[:git_log] = t
    else
      options[:git_log] = nil
    end
  end

  opts.on("-f FILTER", "--filter FILTER ", "time range filter  e.g. last_[day|week|month|year] last_5_[day|week|month|year]   '2022-01-01 08:10:00,2022-10-01 08:10:00'") do |t|
    if t
      range_time = validator_range(t)
      options[:range] = range_time
    else
      options[:range] = nil
    end

  end

  opts.on("-v", "--version", "version") do
    puts "Check996 v#{VERSION}"
    puts ""
    puts "author: Mark24Code"
    puts "repo: https://github.com/Mark24Code/check_996"
    exit 0
  end
end.parse!

# puts options
GitCounter.new(options).run