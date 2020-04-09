# frozen_string_literal: true

require 'pretty_multitask/version'
require 'tlopo/executor'
require 'logger'
require 'pty'
require 'io/console'
require 'io/wait'
require 'socket'
require 'timeout'
require 'yaml'
require 'fileutils'

# Main module
module PrettyMultitask
  require "#{__dir__}/pretty_multitask/color"
  require "#{__dir__}/pretty_multitask/runner"
  require "#{__dir__}/pretty_multitask/run_callable"
end

def pretty_multitask(hash)
  name = hash.keys.first
  tasks = hash.values.first
  task name do
    jobs = []
    tasks.each do |t|
      job = proc do
        Rake::Task[t].invoke
        nil
      end
      jobs.push({ name: t, cmd: job })
    end
    PrettyMultitask::Runner.new(jobs).run
  end
end
