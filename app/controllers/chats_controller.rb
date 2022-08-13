class ChatsController < ApplicationController
  def create
    begin
    # add a lock here on redis for application with key of token
      
      app = Application.find_by!(token: request.headers["TOKEN"])
      app.update!(chats_count: app.chats_count+1)
      CreateChatJob.perform_sync(app.id, app.token, app.chats_count)
      render(
        json: {
          success: true,
          Chat: {
            chat_number: app.chats_count,
            messages_count: 0,  
          }
        },
          status: :created,
      )
    # release the lock
    rescue
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

  def show
    begin
      app = Application.find_by(token: request.headers["TOKEN"])
      chat = app.chats&.find_by(chat_number: chat_params[:chat_number])

      if chat.nil? && chat_params[:chat_number] > app.chats_count
        render json: { error: "no chat was created with this number for this app" }, status: 404
        return
      elsif chat.nil? && chat_params[:chat_number] <= app.chats_count
        chat = {chat_number: chat_params[:chat_number], messages_count: 0}
        
      else
        chat = ChatSerializer.new(chat).to_h
      end

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
