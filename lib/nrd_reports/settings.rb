require 'active_support/concern'

module NrdReports
  module Settings
    extend ActiveSupport::Concern

    private

    def settings
      @settings ||= Setting.plugin_nrd_reports
    end
  end
end
