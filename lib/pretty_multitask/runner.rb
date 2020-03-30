module PrettyMultitask

  LOGGER ||= Logger.new STDOUT
  class Runner
    def initialize(jobs)
      @jobs = jobs
      @jobs.each do |j|
        [:name, :cmd ].each {|o| raise "#{o} must be specified for job #{j}" unless j[o]  }
        j[:out_file] = "/tmp/#{j[:name]}-#{Time.now.strftime('%s.%N')}"
      end
    end
  
    def run
      exec = Tlopo::Executor.new 10
  
      longest= 0
      @jobs.each {|job| longest = job[:name].length if job[:name].length > longest }
      @jobs.each {|job| job[:padding] = longest }
  
      @jobs.each do |j|
        task = proc { j[:exit_status] = RunCallable.new(j).run }
        exec.schedule task
      end
      errors = exec.run.errors
  
      @jobs.each do |j|
        label = "[ #{j[:name]} ]"
        width = IO.console.winsize[-1]
        left = '='*((width - label.length)/2)
        right = j[:name].length.even? ? left : left + '='
        puts "\n"
        puts Color.yellow left +  label + right
        puts File.read j[:out_file]
        puts Color.yellow "="*width
        File.delete j[:out_file]
      end
  
      unless errors.empty?
        errors.each {|e| LOGGER.error e}
        raise 'Found errors'
      end
    end
  
  end

end
