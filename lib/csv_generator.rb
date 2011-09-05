module CsvGenerator
  # The SQL queries do a LEFT JOIN on measurements. If there are more than
  # one measurement per test case the output will contain multiple rows per
  # test case. This is intended - most likely the users of CSV export don't
  # have such cases.

  CSV_REPORT_QUERY = <<-END
    SELECT 
    mtset.name                 AS feature, 
    mtc.name                   AS testcase, 
    if(mtc.result = 1,1,null)  AS pass,
    if(mtc.result = -1,1,null) AS fail,
    if(mtc.result = 0,1,null)  AS na,
    mtc.comment                AS comment,
    mms.name                   AS m_name,
    mms.value                  AS m_value,
    mms.unit                   AS m_unit,
    mms.target                 AS m_target,
    mms.failure                AS m_failure
    FROM features AS mtset
    LEFT JOIN meego_test_cases    AS mtc ON (mtc.feature_id = mtset.id)
    LEFT JOIN meego_test_sessions AS mts ON (mtc.meego_test_session_id = mts.id)
    LEFT JOIN meego_measurements  AS mms ON (mms.meego_test_case_id = mtc.id)
    WHERE mts.id = ? AND mtc.deleted = false
    ORDER BY mtset.id, mtc.id;
  END

  CSV_REPORT_HEADERS = 
    [
     "Feature",
     "Test Case",
     "Pass",
     "Fail",
     "N/A",
     "Comment",
     "Measurement Name",
     "Value",
     "Unit",
     "Target",
     "Failure"
    ]

  CSV_QUERY = <<-END
    SELECT 
    mts.tested_at           AS tested_at, 
    r.name                  AS release_version,
    mts.target              AS target,
    mts.testset             AS testset,
    mts.product             AS product,
    mts.title               AS session,
    mtset.name              AS feature,
    mtc.name                AS testcase, 
    if(mtc.result = 1,1,0)  AS pass,
    if(mtc.result = -1,1,0) AS fail,
    if(mtc.result = 0,1,0)  AS na,
    mtc.comment             AS comment, 
    mms.name                AS m_name,
    mms.value               AS m_value,
    mms.unit                AS m_unit,
    mms.target              AS m_target,
    mms.failure             AS m_failure,
    author.name             AS author,
    editor.name             AS editor
    FROM meego_test_sessions mts
    LEFT JOIN users              AS author ON (mts.author_id = author.id)
    LEFT JOIN users              AS editor ON (mts.editor_id = editor.id)
    LEFT JOIN meego_test_cases   AS mtc    ON (mtc.meego_test_session_id = mts.id)
    LEFT JOIN features           AS mtset  ON (mtc.feature_id = mtset.id)
    LEFT JOIN releases           AS r      ON (mts.release_id = r.id)
    LEFT JOIN meego_measurements AS mms    ON (mms.meego_test_case_id = mtc.id)
  END

  CSV_HEADERS = 
    [
     "Test execution date",
     "MeeGo release",
     "Profile",
     "Test set",
     "Hardware",
     "Test report name",
     "Feature",
     "Test case",
     "Pass",
     "Fail",
     "N/A",
     "Notes",
     "Measurement Name",
     "Value",
     "Unit",
     "Target",
     "Failure",
     "Author",
     "Last modified by"
    ]

  def self.generate_csv(release_version, target, testset, product)
    # Construct conditions
    conds = ["mts.published = ?", "mtc.deleted = ?"]
    conds << "r.name = ?" if release_version
    conds << "mts.target = ?" if target
    conds << "mts.testset = ?" if testset
    conds << "mts.product = ?" if product

    conditions = conds.join(" AND ")

    values = [true, false]
    values << release_version if release_version
    values << target if target
    values << testset if testset
    values << product if product

    query = CSV_QUERY + " WHERE " + conditions + ";"

    result = MeegoTestSession.find_by_sql([query, *values])
 
    FasterCSV.generate(:col_sep => ';') do |csv|
      csv << CSV_HEADERS

      result.each do |row|
        csv << [row[:tested_at], row[:release_version], row[:target], 
                row[:testset], row[:product], row[:session], row[:feature], 
                row[:testcase], row[:pass], row[:fail], row[:na], 
                row[:comment], row[:m_name], row[:m_value], row[:m_unit], 
                row[:m_target], row[:m_failure], row[:author], row[:editor]]
      end
    end
  end

  def self.generate_csv_report(release_version, target, testset, product, id)
    result = MeegoTestCase.find_by_sql([CSV_REPORT_QUERY, id])

    FasterCSV.generate(:col_sep => ',') do |csv|
      csv << CSV_REPORT_HEADERS

      result.each do |row|
        csv << [row[:feature], row[:testcase], row[:pass], row[:fail],
                row[:na], row[:comment], row[:m_name], row[:m_value],
                row[:m_unit], row[:m_target], row[:m_failure]]
      end
    end
  end
end
