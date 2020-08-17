# frozen_string_literal: true

module PrettyMultitask
  module Trapper
    module_function

    PIDS ||= Set.new
    def trap(pid)
      PIDS << pid
      %w[SIGINT SIGTERM SIGHUP].each do |sig|
        Signal.trap(sig) do
          begin
            PIDS.each { |pid| Process.kill sig, pid }
          rescue Errno::ESRCH
            nil
          end
        end
      end
    end
  end
end
