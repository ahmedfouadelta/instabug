class AboutController < ApplicationController
    def index
        x = 10
        byebug
        render json: {
            message: "hello world",
        }, status: 200
    end
end
