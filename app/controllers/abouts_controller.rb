class AboutsController < ApplicationController
    def index
        render json: {
            message: "hello world",
        }, status: 200
    end
end
