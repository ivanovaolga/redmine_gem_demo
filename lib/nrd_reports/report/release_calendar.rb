module NrdReports
  module Report
    class ReleaseCalendar

      attr_reader :issues, :options

      def initialize(*args)
        @issues, @options = args
      end

      def rows
        @rows ||= @issues.select{ |i| i.fixed_version }.map{ |i| ReleaseCalendar::Row.new(i, options) }
      end

    end
  end
end
