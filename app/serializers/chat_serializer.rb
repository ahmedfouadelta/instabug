class ChatSerializer < MainSerializer
  include FastJsonapi::ObjectSerializer
  attributes :chat_number, :messages_count
end
