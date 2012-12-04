class ReportShow < SummaryShow

  delegate :build_id, :created_at, :max_feature_cases, :product, :release, :profile, :testset, :title,
           :to => :@report

  def initialize(report, build_diff=[])
    super(report, build_diff)
  end

  def features
    @features ||= @report.features.map { |feature| FeatureShow.new(feature, @build_diff) }
  end

  def non_empty_features
    @non_empty_features ||= @report.non_empty_features.map { |feature| FeatureShow.new(feature, @build_diff) }
  end

  def as_json(options = nil)
    {
      title: @report.title,
      objective: @report.objective_txt,
      build: @report.build_txt,
      build_id: @report.build_id,
      environment: @report.environment_txt,
      qa_summary: @report.qa_summary_txt,
      issue_summary: @report.issue_summary_txt,
      summary:  super,
      features: features.map {|f| f.as_json(options)},
      prev_session_id: @report.prev_session.id
    }
  end

end
