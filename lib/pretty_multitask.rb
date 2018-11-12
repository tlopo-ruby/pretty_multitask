require "pretty_multitask/version"
require 'tlopo/executor'
require 'logger'
require 'pty'
require 'io/console'
require 'io/wait'
require 'socket'
require 'timeout'
require 'yaml'

module PrettyMultitask
  require "#{__dir__}/pretty_multitask/color"
  require "#{__dir__}/pretty_multitask/runner"
  require "#{__dir__}/pretty_multitask/run_callable"
end

def pretty_multitask(hash)
  name, tasks = hash.keys.first, hash.values.first
  task name do
    jobs = []
    tasks.each do |t|
      job = Proc.new do 
        Rake::Task[t].invoke
        nil
      end
      jobs.push({ name: t, cmd: job})
    end
    PrettyMultitask::Runner.new(jobs).run
  end
end
