class Index

  CUT_OFF_LIMIT = 30

  QUERY = "
    SELECT DISTINCT profiles.name AS profile, reports.testset, reports.product AS name
    FROM profiles
    LEFT JOIN meego_test_sessions AS reports ON profiles.id = reports.profile_id AND
      reports.release_id = ? AND
      reports.published  = TRUE AND
      reports.tested_at  > ?
    ORDER BY profiles.sort_order ASC, testset, product
  "

  def self.find_by_release(release, scope)
    { :profiles => Profile.find_by_sql(
        [QUERY, release.id, scope == 'all' ? 0 : CUT_OFF_LIMIT.days.ago]
      ).group_by(&:profile).map do |profile, testsets|
        unless APP_CONFIG['hide_empty_targets'] == true and testsets.select{|ts| ts.testset.present?}.count == 0
          {
            :name     => profile,
            :url      => "/#{release.name}/#{profile}",
            :testsets => testsets.select{|ts| ts.testset.present?}.group_by(&:testset).map do |testset, products|
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
    }
  end

  def self.comparison_url(release, profile, testset)
    testset_base   = testset.split(":")[0]
    comparetype    = testset_base + ":Testing"
    comparison_url = "/#{release.name}/#{profile}/#{testset_base}/compare/#{comparetype}"
    comparison_url if MeegoTestSession.release(release.name).profile(profile).testset(comparetype.capitalize).count > 0
  end
end
