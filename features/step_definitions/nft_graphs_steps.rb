When "I upload two NFT test reports" do
  FactoryGirl.create(:nft_test_report, :tested_at => '2011-08-08')
  FactoryGirl.create(:nft_test_report, :tested_at => '2011-08-09')
end

When "I click on the first NFT trend button" do
  When %{I click on element "//a[@class='nft_trend_button']"}
end

When "I click on the first NFT trend graph" do
  When %{I click on element "//canvas[contains(@id, 'nft-history-graph')]"}
end

When "I click on the first NFT serial measurement trend graph" do
  When %{I click on element "//canvas[contains(@id, 'serial-history-graph')]"}
end

When "I close the trend dialog" do
  When %{I click on element "//a[@class='ui_btn modal_close']"}
end
