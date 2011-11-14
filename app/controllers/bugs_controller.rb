class BugsController < ApplicationController

  caches_action :fetch_bugzilla_data,
                :cache_path => Proc.new { |controller| controller.bugzilla_cache_key },
                :expires_in => 1.hour

  def fetch_bugzilla_data
    ids       = params[:bugids]

    uri = BUGZILLA_CONFIG['uri'] + ids.join(',')

    content = ""
    if not BUGZILLA_CONFIG['proxy_server'].nil?
      @http = Net::HTTP.Proxy(BUGZILLA_CONFIG['proxy_server'], BUGZILLA_CONFIG['proxy_port']).new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    else
      @http = Net::HTTP.new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    end

    @http.use_ssl     = BUGZILLA_CONFIG['use_ssl']
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http.start() do |http|
      req = Net::HTTP::Get.new(uri)
      if not BUGZILLA_CONFIG['http_username'].nil?
        req.basic_auth BUGZILLA_CONFIG['http_username'], BUGZILLA_CONFIG['http_password']
      end
      response = http.request(req)
      content = response.body
    end

    # XXX: bugzilla seems to encode its exported csv to utf-8 twice
    # so we convert from utf-8 to iso-8859-1, which is then interpreted
    # as utf-8
    begin
      content = Iconv.iconv("iso-8859-1", "utf-8", content).join '\n'
    rescue Iconv::IllegalSequence
      # Better to return something than nothing if conversion fails,
      # so just handle the original response in whatever charset it is
    end

    begin
      json = FasterCSV.parse(content)
      # TODO: Should render json instead of CSV
      render :json => json
    rescue FasterCSV::MalformedCSVError => e
      logger.error e.message
      logger.info  "ERROR: MALFORMED BUGZILLA DATA"
      logger.info  data
      head :not_found
    end
  end

  protected

  def bugzilla_cache_key
    h = Digest::SHA1.hexdigest params.to_hash.to_a.map{|k,v| if v.respond_to?(:join) then k+v.join(",") else k+v end}.join(';')
    "bugzilla_#{h}"
  end

end
