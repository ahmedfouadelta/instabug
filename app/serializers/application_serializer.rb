class ApplicationSerializer < MainSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :token, :chats_count
  
end
