class ChatsController < ApplicationController
  def initialize
    @redis = Redis.new(host: "host.docker.internal")
  end

  def create #done
    begin
      app_lock_val = add_lock("Lock_Application_#{request.headers["TOKEN"]}"); raise if app_lock_val == false
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      if app.nil?
        remove_lock("Lock_Application_#{request.headers["TOKEN"]}", app_lock_val)
        return render json: { error: "Application's not found" }, status: 404
      end

      app.chats_count += 1
      chat = Chat.new(
        application_token: app.token,
        chat_number: app.chats_count,
        messages_count: 0
      )

      CreateOrUpdateApplicationJob.perform_in(20.seconds, app.token)
      CreateOrUpdateChatJob.perform_in(20.seconds, app.token, app.chats_count)

      success = @redis.multi do |multi|
        multi.set("Application_#{request.headers["TOKEN"]}", app.to_json, px: 86400000)
        multi.set("Chat_#{request.headers["TOKEN"]}_#{app.chats_count}", chat.to_json, px: 86400000)
      end

      remove_lock("Lock_Application_#{request.headers["TOKEN"]}", app_lock_val)
      raise if success != ["OK", "OK"]

      render(
        json: {
          success: true,
          Chat: ChatSerializer.new(chat).to_h, 
        },
          status: :ok,
      )
    rescue
      remove_lock("Lock_Application_#{request.headers["TOKEN"]}", app_lock_val)
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  def index
    begin
      app = Application.find_by!(token: request.headers["TOKEN"])

      all_chats_number = Array(1..app.chats_count)
      created_chats_number = app.chats.order("chat_number ASC").pluck(:chat_number)
      not_created_yet_chats_number = all_chats_number - created_chats_number
      arr_of_chats = ChatSerializer.new(app.chats).to_h

      not_created_yet_chats_number.each do |chat_number|
        arr_of_chats.push({chat_number: chat_number, messages_count: 0})
      end

      render(
        json: {
          success: true,
          Chats: arr_of_chats, 
        },
          status: :ok,
      )
    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
      
  end

  def show #done
    begin
      app = ApplicationRepo.new.load_app(request.headers["TOKEN"])
      return render json: { error: "Application's not found" }, status: 404  if app.nil?

      chat = ChatRepo.new.load_chat(request.headers["TOKEN"], chat_params[:chat_number])
      return render json: { error: "Chat's not found" }, status: 404 if chat.nil?

      render(
        json: {
          success: true,
          Chat: chat, 
        },
          status: :ok,
      )
    rescue
      render json: { error: "Something went wrong" }, status: 500
    end
  end

  private

  def chat_params
    params.require(:chat).permit(:chat_number)
  end

end
