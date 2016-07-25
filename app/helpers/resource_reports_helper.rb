module ResourceReportsHelper
  def report_releases_options
    possible_releases.map{ |r| [r.name, r.id] }
  end
end
