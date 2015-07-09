require_relative 'base'

module AdminUI
  class BaseViewModel < AdminUI::Base
    def initialize(logger, cc, log_files, stats, tasks, varz, testing)
      super(logger)

      @cc        = cc
      @log_files = log_files
      @stats     = stats
      @tasks     = tasks
      @varz      = varz
      @testing   = testing

      @running = true
    end

    def shutdown
      @running = false
    end
  end
end
