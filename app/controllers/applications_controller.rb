require "redis"
class ApplicationsController < ApplicationController
  def create
    begin
      app = Application.create!(name: application_params[:name], token: (SecureRandom.hex 12))
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

  def show
    begin
      app = Application.find_by!(token: request.headers["TOKEN"])
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

  def update
    begin
      app = Application.find_by(token: request.headers["TOKEN"])
      app.update!(name: application_params[:name])
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
