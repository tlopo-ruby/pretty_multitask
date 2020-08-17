# frozen_string_literal: true

module PrettyMultitask
  # This class will run a callable, and wrap it's output adding nice format
  class RunCallable
    def initialize(opts = {})
      @opts = opts
    end

    def run(opts = @opts)
      cmd = opts[:cmd]
      name = opts[:name]
      out = STDOUT
      @padding = opts[:padding]
      master, slave = PTY.open
      err_read, err_write = IO.pipe

      r, w = UNIXSocket.pair(:STREAM, 0)

      pid = run_on_fork(cmd, err_write, master, w)
      Trapper.trap pid

      t_out = consume_and_print slave, out, name, false
      t_err = consume_and_print err_read, out, name, true

      chars = []
      t = consume_and_store r, chars

      Process.wait pid

      wait_until_streams_are_ready [slave, err_read]

      join_threads [t_out, t_err, t]

      close_streams [master, slave, err_read, err_write]

      result = Marshal.load(chars.join)
      raise result[:error] if result[:error]

      result[:result]
    end

    def consume_and_store(reader, store)
      t = Thread.new do
        sleep 0.1 until reader.ready?
        3.times do
          store << reader.getc while reader.ready?
        end
      end
      t
    end

    def wait_until_streams_are_ready(streams)
      streams.each do |s|
        loop { break unless s.ready? }
      end
    end

    def join_threads(threads)
      threads.each do |t|
        begin
          Timeout.timeout(0.1) { t.join }
        rescue Timeout::Error
          nil
        end
      end
    end

    def close_streams(streams)
      streams.each(&:close)
    end

    def run_on_fork(cmd, err_w, out_w, socket_w)
      pid = fork do
        STDERR.reopen err_w
        STDOUT.reopen out_w
        begin
          result = cmd.call
          obj = { result: result, error: nil }
        rescue StandardError => e
          new_error = e.class.new(e.message)
          new_error.set_backtrace e.backtrace
          Logger.new(STDERR).error new_error
          obj = { result: nil, error: new_error }
          socket_w.puts Marshal.dump(obj), 0
        end
        socket_w.puts Marshal.dump(obj), 0
        socket_w.close
      end
      pid
    end

    def consume_and_print(reader, writer, name, error = false)
      Thread.new do
        begin
          fmt = "%#{@padding}s |"
          colored = Color.red format(fmt, name) if error
          colored = Color.green format(fmt, name) unless error
          reader.each_line do |line|
            writer.write "#{colored} #{line}"
            next unless @opts[:out_file]

            File.open(@opts[:out_file], 'a+') do |f|
              f.puts "#{colored} #{line}" if error
              f.puts "#{colored} #{line}" unless error
            end
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
