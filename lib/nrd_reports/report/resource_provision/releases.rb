module NrdReports
  module Report
    class ResourceProvision::Releases < ResourceProvision
      unloadable
      include Redmine::I18n
      include NrdReports::Settings

      def create_rows
        @rows = {}

        calc_available_resources
        calc_rework_values
        calc_additional_resources
      end

      private

      def res_row
        sum_row = { available: 0, required: 0, deficit: 0, additional: 0 }
        { an: sum_row.dup, dev: sum_row.dup, test: sum_row.dup }
      end

      def resource_quantum
        @quantum ||= find_resource_quantum
      end

      def find_resource_quantum
        quantum = Issue.joins(:custom_values, :parent)
          .where(
            tracker_id: settings[:resource_quantum_tracker],
            custom_values:    {
              custom_field_id: settings[:quantum_type_field],
              value:           settings[:quantum_type_work]
            },
            parents_issues: {
              tracker_id: settings[:resource_tracker],
            }
          )
          .preload(:custom_values, :resource_volume, parent: :resource_category)
        filter_release_version(quantum)
      end

      def calc_available_resources
        return unless resource_quantum

        resource_quantum.each do |q|
          type = quantum_type(q)
          next unless type

          @rows[q.fixed_version_id] ||= res_row
          @rows[q.fixed_version_id][type][:available] += q.resource_volume.value.to_f
        end
      end

      def calc_rework_values
        reworks.each do |r|
          type = rework_type(r)
          next unless type

          @rows[r.fixed_version_id] ||= res_row

          @rows[r.fixed_version_id][type][:required] += calc_rework_required(r)
          @rows[r.fixed_version_id][type][:deficit]  += calc_deficit(@rows[r.fixed_version_id][type])
        end
      end

      def quantum_type(quantum)
        category = quantum.parent.resource_category.try(:value)
        if category == settings[:category_analytics]
          :an
        elsif category == settings[:category_dev]
          :dev
        elsif category == settings[:category_test]
          :test
        end
      end

      def calc_deficit(row)
        deficit = row[:required] - row[:available]
        deficit > 0 ? deficit : 0
      end

      def calc_additional_resources
        return unless resource_quantum

        systems = {}
        resource_quantum.each do |q|
          system = q.custom_field_value(settings[:system_field])
          systems[q.fixed_version_id] = system if system.present?
        end

        release_issues.each do |r|
          system     = systems[r.fixed_version_id]
          competence = Competence.find_by_months(1, system).try(:value) if system
          competence ||= 0

          [:an, :dev, :test].each { |t| calc_additional_value(t, r, competence) }
        end
      end

      def calc_additional_value(type, release_issue, competence)
        version_id = release_issue.fixed_version_id
        work_days  = release_work_days(release_issue, type)

        if work_days > 0 && competence > 0
          deficit = @rows[version_id][type][:deficit]

          @rows[version_id] ||= res_row
          @rows[version_id][type][:additional] = deficit / (work_days * 0.9) / (0.8 * 0.7 * competence)
        end
      end

    end
  end
end
