require "redis"
class ApplicationsController < ApplicationController
  def initialize
    @redis = Redis.new(host: "host.docker.internal")
  end

  def create #done
    begin
      token = SecureRandom.hex 12
      app = Application.new(
        name: application_params[:name],
        token: token
      )

      CreateOrUpdateApplicationJob.perform_in(20.seconds, app.token)
      @redis.set("Application_#{app.token}", app.to_json, px: 86400000)

      render(
        json: {
          success: true,
          Application: ApplicationSerializer.new(app).to_h,
        },
          status: :created,
      )

    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  def show #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?
      render(
        json: {
          success: true,
          Application: ApplicationSerializer.new(app).to_h,
        },
          status: :ok
      )

    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  def update #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      app = Application.new(app.attributes.merge!(name: application_params["name"]))

      CreateOrUpdateApplicationJob.perform_in(20.seconds, app.token)
      @redis.set(
        "Application_#{app.token}", app.to_json, px: 86400000
      )

      render(
        json: {
          success: true,
          Application: ApplicationSerializer.new(app).to_h,
        },
          status: :ok
      )

    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  private

  def application_params
    params.require(:application).permit(:name)
  end
end
