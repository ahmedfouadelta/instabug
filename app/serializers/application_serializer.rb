class ApplicationSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :token, :chats_count
  
end
