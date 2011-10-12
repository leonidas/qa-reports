class Index

  def self.find_by_release(release)
    { :profiles => find_profiles(release) }
  end

  def self.find_by_lateset_release(release)
    { :profiles => find_profiles_latest_month(release) }
  end

  private

  def self.find_profiles(release)
    TargetLabel.find_by_sql("
      SELECT DISTINCT profiles.label AS profile, reports.testset, reports.product AS name
      FROM target_labels AS profiles
      LEFT JOIN meego_test_sessions AS reports ON profiles.normalized = reports.target AND reports.release_id = #{release.id} AND reports.published = TRUE
      ORDER BY profiles.sort_order ASC, testset, product
    ").group_by(&:profile).map do |profile, testsets|
      {
        :name     => profile,
        :url      => "/#{release.name}/#{profile}",
        :testsets => testsets.first.testset.nil? ? [] : testsets.group_by(&:testset).map do |testset, products|
            {
              :name           => testset,
              :url            => "/#{release.name}/#{profile}/#{testset}",
              :comparison_url => comparison_url(release, profile, testset),
              :products       => products.map do |product|
                {
                  :name => product.name,
                  :url  => "/#{release.name}/#{profile}/#{testset}/#{product.name}"
                }
              end
            }
          end
      }
    end
  end

  def self.find_profiles_latest_month(release)
    last_month = 1.months.until(Time.now)
    last_month_datetime = last_month.strftime('%Y-%m-%d %H:%M:%S')
    TargetLabel.find_by_sql("
      SELECT DISTINCT profiles.label AS profile, reports.testset, reports.product AS name
      FROM target_labels AS profiles
      LEFT JOIN meego_test_sessions AS reports ON profiles.normalized = reports.target AND reports.release_id = #{release.id} AND reports.published = TRUE AND created_at > '#{last_month_datetime}'
      ORDER BY profiles.sort_order ASC, testset, product
    ").group_by(&:profile).map do |profile, testsets|
      {
        :name     => profile,
        :url      => "/#{release.name}/#{profile}",
        :testsets => testsets.first.testset.nil? ? [] : testsets.group_by(&:testset).map do |testset, products|
            {
              :name           => testset,
              :url            => "/#{release.name}/#{profile}/#{testset}",
              :comparison_url => comparison_url(release, profile, testset),
              :products       => products.map do |product|
                {
                  :name => product.name,
                  :url  => "/#{release.name}/#{profile}/#{testset}/#{product.name}"
                }
              end
            }
          end
      }
    end
  end

  def self.comparison_url(release, profile, testset)
    testset_base   = testset.split(":")[0]
    comparetype    = testset_base + ":Testing"
    comparison_url = "/#{release.name}/#{profile}/#{testset_base}/compare/#{comparetype}"
    comparison_url if MeegoTestSession.release(release.name).profile(profile).testset(comparetype.capitalize).count > 0
  end
end
