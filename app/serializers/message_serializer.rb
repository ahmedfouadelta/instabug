class MessageSerializer < MainSerializer
  include FastJsonapi::ObjectSerializer
  attributes :message_number, :body
end
