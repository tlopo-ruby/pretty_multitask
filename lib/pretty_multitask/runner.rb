# frozen_string_literal: true

module PrettyMultitask
  # This class will run multiple callables in parallel using RunCallable which add a nice format
  class Runner
    LOGGER ||= Logger.new STDOUT
    def initialize(jobs)
      @jobs = jobs
      @jobs.each do |j|
        %i[name cmd].each { |o| raise "#{o} must be specified for job #{j}" unless j[o] }
        j[:out_file] = "/tmp/#{j[:name]}-#{Time.now.strftime('%s.%N')}"
        FileUtils.touch j[:out_file]
      end
    end

    def run
      exec = Tlopo::Executor.new 10

      @jobs.each { |job| job[:padding] = longest_jobname }
      @jobs.each do |j|
        task = proc { j[:exit_status] = RunCallable.new(j).run }
        exec.schedule task
      end
      errors = exec.run.errors

      print_out

      unless errors.empty?
        errors.each { |e| LOGGER.error e }
        raise 'Found errors'
      end
    end

    def print_out
      @jobs.each do |j|
        label = "[ #{j[:name]} ]"
        width = IO.console.winsize[-1]
        width = 80 unless width > 0
        left = '=' * ((width - label.length) / 2)
        right = j[:name].length.even? ? left : left + '='
        puts "\n"
        puts Color.yellow left + label + right
        puts File.read j[:out_file]
        puts Color.yellow '=' * width
        File.delete j[:out_file]
      end
    end

    def longest_jobname
      longest = 0
      @jobs.each { |job| longest = job[:name].length if job[:name].length > longest }
      longest
    end
  end
end
