require 'fileutils'
require 'xml_result_file_parser'
require 'csv_result_file_parser'
require 'parse_error'

class ReportFactory

  def build(params)
    @errors = {}

    begin
      generate_title(params)
      parse_result_files(params)
      test_session = MeegoTestSession.new(params)
      copy_template_values(test_session)

    rescue ParseError => e
      Rails.logger.error "ERROR IN FILE PARSING: " + e.filename
      Rails.logger.error "ERROR MESSAGE: " + e.message
      test_session = MeegoTestSession.new(params)
      test_session.errors.add(:result_files, e.message)
    end

    test_session
  end

  private

  def generate_title(params)
    params[:tested_at] = Time.now.to_s unless params[:tested_at].present?

    tested_at = DateTime.parse(params[:tested_at]).strftime('%Y-%m-%d')
    title_values = [params[:target], params[:product], params[:testset], tested_at]
    params[:title] ||= "%s Test Report: %s %s %s" % title_values
  end

  def parse_result_files(params)
    features = {}

    params[:result_files] ||= []
    params[:result_files_attributes] ||= []
    params[:result_files] += params.delete(:result_files_attributes).map do |file|
      FileAttachment.new file
    end

    params[:result_files].each do |result_attachment|
      file = result_attachment.file.to_file
      if result_attachment.filename =~ /.csv$/i
        new_features = CSVResultFileParser.new.parse(file.read)
      elsif result_attachment.filename =~ /.xml$/i
        begin
          new_features = XMLResultFileParser.new.parse(file.read)
        rescue Nokogiri::XML::SyntaxError => e
          raise ParseError.new(result_attachment.filename), result_attachment.filename + ": " + e.message
        end
      else
        raise ParseError.new(result_attachment.filename), "You can only upload files with the extension .xml or .csv"
      end

      raise ParseError.new(result_attachment.filename), result_attachment.filename + " didn't contain any valid test cases" if new_features.empty?

      merge_results(features, new_features)
    end

    params[:features_attributes] = features.map do |feature, test_cases|
      { :name => feature, :meego_test_cases_attributes => test_cases.values }
    end
  end

  def merge_results(features, new_features)
    new_features.each do |feature, tcs|
      features[feature] ||= {}
      features[feature].merge!(tcs)
    end
  end

  def sanitize_filename(filename)
    filename.gsub(/[^\w\.\_\-]/, '_')
  end

  def copy_template_values(test_session)
    prev = test_session.prev_session

    if prev
      test_session.objective_txt     = prev.objective_txt     if test_session.objective_txt.empty?
      test_session.build_txt         = prev.build_txt         if test_session.build_txt.empty?
      test_session.environment_txt   = prev.environment_txt   if test_session.environment_txt.empty?
      test_session.qa_summary_txt    = prev.qa_summary_txt    if test_session.qa_summary_txt.empty?
      test_session.issue_summary_txt = prev.issue_summary_txt if test_session.issue_summary_txt.empty?

      copy_previous_test_case_comments(test_session, prev)
    end

    test_session.generate_defaults!
  end

  def copy_previous_test_case_comments(test_session, prev)
    test_session.features.each do |feature|
      feature.meego_test_cases.each do |tc|
        prev_tc = prev.test_case_by_name(feature.name, tc.name)

        if prev_tc and tc.result == prev_tc.result and tc.comment.blank?
          tc.comment = prev_tc.comment
        end
      end
    end
  end
end
