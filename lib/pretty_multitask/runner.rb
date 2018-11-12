module PrettyMultitask

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
        padding = ( longest -  j[:name].length )/2
        left = '='*35
        left += '='*padding
        right = j[:name].length.even? ? left : left + '='
        puts "\n"
        label = "[ #{j[:name]} ]"
        puts Color.yellow left +  "[ #{j[:name]} ]" + right
        puts File.read j[:out_file]
        puts Color.yellow left + label.gsub(/./,'=') + right
        File.delete j[:out_file]
      end
  
      unless errors.empty?
        LOGGER.fatal 'Found errors'
        exit 2
      end
    end
  
  end

end
