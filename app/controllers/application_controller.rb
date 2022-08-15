require "redis"
class ApplicationController < ActionController::API
  before_action :redis_object
  
  def add_lock(key)
    val = SecureRandom.hex 12

    4.times do
      locked = @redis.setnx(key,val)
      return val if(locked == true)
      sleep 0.05
    end
    return false
  end

  def remove_lock(key, val)
    val_on_redis = @redis.get(key)
    if(val == val_on_redis && !val_on_redis.nil? )
      @redis.del(key, val)
      return true
    else
      return false
    end
  end

  private

  def redis_object
    @redis = Redis.new(host: "host.docker.internal")
  end
end

# val = add_lock("a"); raise if val == false
# raise if remove_lock("a", val) == false 
