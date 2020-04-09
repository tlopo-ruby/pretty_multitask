module PrettyMultitask 

  class RunCallable
    def initialize(opts = {})
      @opts = opts
    end
  
    def run(opts = @opts)
      cmd = opts[:cmd]
      name = opts[:name]
      out = opts[:out] || STDOUT
      err = opts[:err] || STDERR
      @padding = opts[:padding]
      master, slave = PTY.open
      err_read, err_write = IO.pipe
  
      r, w = UNIXSocket.pair(:STREAM, 0)
  
      pid = fork do
        STDERR.reopen err_write
        STDOUT.reopen master
        begin
          result = cmd.call
          obj = { result: result, error: nil }
        rescue StandardError => e
          new_error = e.class.new(e.message)
          new_error.set_backtrace e.backtrace
          Logger.new(STDERR).error new_error
          obj = { result: nil, error: new_error }
          File.open('/tmp/error','w+'){|f| f.puts obj.to_yaml}
          w.puts Marshal.dump(obj), 0
        end
        w.puts Marshal.dump(obj), 0
        w.close
      end

      t_out = consume_and_print slave, out, name, false
      t_err = consume_and_print err_read, out, name, true

      chars = []
      t = Thread.new do
        sleep 0.1 until r.ready?
        (1..3).each do 
          chars << r.getc while r.ready?
        end
      end

      Process.wait pid
      Timeout.timeout(1) { t.join }
  
      %i[slave err_read].each do |e|
        loop { break unless binding.local_variable_get(e).ready? }
      end
  
      begin
        Timeout.timeout(0.1) do
          %i[t_out t_err].each { |e| binding.local_variable_get(e).join }
        end
      rescue Timeout::Error
        nil
      end
  
      %i[master slave err_read err_write].each { |e| binding.local_variable_get(e).close }
  
  
      result = Marshal.load(chars.join)
      raise result[:error] if result[:error]
  
      result[:result]
    end

    def consume_and_print(reader, writer, name, error = false)
      Thread.new do
        begin
          fmt = "%#{@padding}s |"
          colored = Color.red format(fmt, name) if error
          colored = Color.green format(fmt, name) unless error
          reader.each_line do |line|
            writer.write "#{colored} #{line}"
            File.open(@opts[:out_file],'a+') do |f|
              f.puts "#{colored} #{line}" if error
              f.puts "#{colored} #{line}" unless error
            end if @opts[:out_file]
          end
        rescue Errno::EIO
          nil
        rescue IOError
          nil
        end
      end
    end
  end
end
