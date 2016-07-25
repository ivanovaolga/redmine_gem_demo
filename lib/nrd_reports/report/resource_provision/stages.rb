module NrdReports
  module Report
    class ResourceProvision::Stages < ResourceProvision
      unloadable

      def initialize(releases, rdp, systems_report)
        @systems_report = systems_report

        super(releases, rdp)
      end

      private

      def create_rows
        @rows = {}
        @release_ids.each { |r| @rows[r] = def_row }

        find_stages
        find_systems
        calc_availabilities
        calc_volumes
      end

      def find_stages
        release_issues.each do |release_issue|
          r_version = release_issue.fixed_version_id
          @rows[r_version][:stage] = release_issue.status.name if r_version
        end
      end

      def find_systems
        reworks.each do |rework|
          system = rework.custom_field_value(settings[:system_field])
          @rows[rework.fixed_version_id][:system] = system if system
        end
      end

      def calc_availabilities
        @systems_report.rows.each do |r_id, release_data|
          release_data.each_value do |row|
            row.each_value do |data|
              @rows[r_id][:available_min] += data[:availability_min] * 8
              @rows[r_id][:available_max] += data[:availability_max] * 8
            end
          end
        end
      end


      def calc_volumes
        @systems_report.total_row.each do |r_id, release_data|
          release_data.each_value do |row|
            @rows[r_id][:required] += row[:required]
            @rows[r_id][:deficit]  += row[:deficit]
          end
        end
      end

      def def_row
        {
          stage:         '',
          system:        '',
          available_min: 0,
          available_max: 0,
          required:      0,
          deficit:       0
        }
      end

    end
  end
end
