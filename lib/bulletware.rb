class Bulletware
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless Bullet.enable?

    Bullet::Association.start_request
    status, headers, response = @app.call(env)
    return [status, headers, response] if response.empty?

    if Bullet::Association.has_unpreload_associations?
      if !headers['Content-Type'].nil? and headers['Content-Type'].include? 'text/html'
        response_body = response.body.insert(-17, Bullet::Association.unpreload_associations_alert)
        headers['Content-Length'] = response_body.length.to_s
      end

      Bullet::Association.log_unpreload_associations(env['PATH_INFO'])
    end
    response_body ||= response.body
    Bullet::Association.end_request
    [status, headers, response_body]
  end
end
