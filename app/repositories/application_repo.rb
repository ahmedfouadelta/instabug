require "redis"
class ApplicationRepo
  def load_app(application_token)
    redis = Redis.new(host: "host.docker.internal")
    app_json = redis.get("Application_#{application_token}")
    return Application.new(JSON.parse(app_json)) if app_json.present?

    app = Application.find_by(token: application_token)
    return nil if app.nil?

    redis.set("Application_#{application_token}", app.to_json, nx: true, px: 86400000)
    return app
  end
end
