When %r/^I fetch the (.*)rss feed for "([^"]*)"$/ do |sort, filter|
  filter = "/#{filter}" unless (filter.start_with?("/") or filter =~ URI::regexp)
  uri    = filter + "/rss"
  uri    = uri    + "/tested_at" if defined? sort
  visit(uri)
end

Then %r/^I should see (\d+) instance(?:s)? of "([^"]*)"$/ do |num, selector|
  page.has_css?(selector, :count => num.to_i).should eql(true), "Expected #{num} '#{selector}'(s)"
end

Then %r/^I should see the page header offer RSS feed for "([^"]*)"$/ do |rssfeed|
  rsslink = "/" + rssfeed + "/rss"
  assert page.has_css?("head link[href=\"#{rsslink}\"]")
end





