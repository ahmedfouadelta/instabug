require "redis"
class ApplicationsController < ApplicationController
  def create
    begin
      app = Application.create!(name: application_params[:name], token: (SecureRandom.hex 12))
      
      render(
        json: {
          success: true,
          Application: ApplicationSerializer.new(app).to_hash[:data][:attributes],
        },
          status: :created,
      )

    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  def show
  end

  def update
    begin
      app = Application.find_by(token: request.headers["TOKEN"])
      app.update!(name: application_params[:name])
      render(
        json: {
          success: true,
          Application: ApplicationSerializer.new(app).to_hash[:data][:attributes],
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
