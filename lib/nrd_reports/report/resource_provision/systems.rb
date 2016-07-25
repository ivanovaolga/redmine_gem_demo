module NrdReports
  module Report
    class ResourceProvision::Systems < ResourceProvision
      unloadable

      attr_accessor :total_row

      def initialize(releases, rdp, resources_report)
        @resources_report = resources_report

        super(releases, rdp)
      end

      private

      def create_rows
        @rows = {}
        @release_ids.each do |r|
          @rows[r] = {}
          systems.each { |s| @rows[r][s] = res_row }
        end

        calc_systems_required
        calc_availabilities
        calc_totals
        calc_deficit
      end

      def res_row
        data = { availability_min: 0, availability_max: 0, required: 0, deficit: 0, availability_rate: 0 }
        { an: data, dev: data.dup, test: data.dup }
      end

      def systems
        @systems ||= CustomField.find(settings[:system_field]).possible_values
      end

      def calc_availabilities
        @resources_report.rows.each do |release_id, release|
          next if @release_ids && !@release_ids.include?(release_id)

          release[:data].each do |c, category_data|
            category_data.each do |row|
              row[:systems].each do |system, av|
                next unless @rows[release_id].try(:[], system).try(:[], c)

                systems_num = resource_systems[row[:resource].id].try(:size).to_i
                @rows[release_id][system][c][:availability_min] += av.to_f if systems_num <= 1
                @rows[release_id][system][c][:availability_max] += av.to_f if systems_num >= 1
              end
            end
          end
        end
      end

      def resource_systems
        @resource_systems ||= find_resource_systems
      end

      def find_resource_systems
        resource_systems = []
        release_quantum.each do |q|
          system = q.custom_field_value(settings[:system_field])
          resource_systems[q.parent_id] ||= []
          resource_systems[q.parent_id].push(system).uniq!
        end
        resource_systems
      end

      def release_quantum
        release_quantum = Issue.joins(:custom_values)
          .where(
            tracker_id:       settings[:resource_quantum_tracker],
            custom_values:    {
              custom_field_id: settings[:quantum_type_field],
              value:           settings[:quantum_type_work]
            }
          ).preload(:custom_values).uniq
        filter_release_version(release_quantum)
      end

      def calc_systems_required
        reworks.each do |r|
          type   = rework_type(r)
          system = r.custom_field_value(settings[:system_field])
          next unless type && @rows[r.fixed_version_id].try(:[], system)

          @rows[r.fixed_version_id][system][type][:required] += calc_rework_required(r)
        end
      end

      def calc_deficit
        calc_availability_rates

        @rows.each do |r_id, release_data|
          release_data.each_value do |row|
            row.each do |type, data|
              total_deficit  = @total_row[r_id][type][:deficit]
              total_rate     = @total_rates[r_id][type]
              deficit_rate   = total_rate > 0 ? data[:availability_rate] / total_rate : 0
              data[:deficit] = (total_deficit * deficit_rate).round(2)
            end
          end
        end
      end

      def calc_availability_rates
        releases = release_issues
        @total_rates = {}

        @rows.each do |r_id, release_data|
          release_issue = releases.find { |r| r.fixed_version_id == r_id }
          release_data.each do |system, row|
            row.each do |type, data|
              if release_issue
                work_days = release_work_days(release_issue, type)
                rate = data[:availability_min] * work_days * 0.9
                @rows[r_id][system][type][:availability_rate] = data[:availability_min] * work_days * 0.9
              else
                rate = 0
              end

              @rows[r_id][system][type][:availability_rate] = rate
              @total_rates[r_id] ||= { an: 0, dev: 0, test: 0 }
              @total_rates[r_id][type] += @rows[r_id][system][type][:availability_rate]
            end
          end
        end
      end

      def calc_totals
        init_totals
        calc_total_availability
        calc_total_required
        calc_total_deficit
      end

      def init_totals
        data       = { availability: 0, calc_availability: 0, required: 0, deficit: 0 }
        @total_row = {}
        @release_ids.each { |r| @total_row[r] = { an: data.dup, dev: data.dup, test: data.dup } }
      end

      def calc_total_availability
        @resources_report.rows.each do |r_id, release|
          next if @release_ids && !@release_ids.include?(r_id)

          release[:data].each do |c, category_data|
            unless c == 'empty'
              @total_row[r_id][c][:availability]      += category_data.map{ |r| r[:availability] || 0 }.sum
              @total_row[r_id][c][:calc_availability] += category_data.map{ |r| r[:availability_ni] || 0 }.sum
            end
          end
        end
      end

      def calc_total_required
        @rows.each do |r_id, release_data|
          release_data.each_value do |row|
            row.each { |t, data| @total_row[r_id][t][:required] += data[:required] }
          end
        end
      end

      def calc_total_deficit
        @total_row.each_value do |release_data|
          release_data.each_value do |row|
            deficit = row[:required] - row[:calc_availability]
            row[:deficit] = deficit > 0 ? deficit : 0
          end
        end
      end

    end
  end
end
