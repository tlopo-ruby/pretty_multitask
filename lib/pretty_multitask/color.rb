module PrettyMultitask
  class Color
    def self.green(str)
      "\e[32;1m#{str}\e[0m"
    end
    def self.yellow(str)
      "\e[33;1m#{str}\e[0m"
    end
    def self.red(str)
      "\e[31;1m#{str}\e[0m"
    end
  end
end

