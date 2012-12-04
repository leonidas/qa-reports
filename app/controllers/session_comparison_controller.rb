require 'report_comparison'

class SessionComparisonController < ApplicationController
  layout "report"

  def show
    if params[:compare_id].eql?("previous")
        @reports = [MeegoTestSession.fetch_for_comparison(params[:id]).prev_session,
                    MeegoTestSession.fetch_for_comparison(params[:id])]
        @ids = [@reports[0].id, params[:id]]
    else
        @ids = [params[:id], params[:compare_id]]
        @reports = [MeegoTestSession.fetch_for_comparison(@ids[0]),
                    MeegoTestSession.fetch_for_comparison(@ids[1])]
    end

    # Need values for breadcrumb. Profile is always same
    # for both reports
    @profile = @reports[0].profile
    # Add testset and product to breadcrumb only if they're
    # the same for both reports, i.e. user most likely selected
    # comparison from testset or product level. And even if didn't
    # the breadcrumb is still correct
    if @reports[0].testset == @reports[1].testset
      @testset = @reports[0].testset
      if @reports[0].product == @reports[1].product
        @product = @reports[0].product
      end
    end

    @compare_cache_key = "compare_page_#{@ids[0]}_#{@ids[1]}"

    @comparison = ReportComparison.new(@reports[0], @reports[1])

    respond_to do |format|
      format.html
      format.json { render json: @comparison }
    end
  end
end
