require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get messages_create_url
    assert_response :success
  end

  test "should get update" do
    get messages_update_url
    assert_response :success
  end

  test "should get show" do
    get messages_show_url
    assert_response :success
  end

  test "should get list" do
    get messages_list_url
    assert_response :success
  end

  test "should get search" do
    get messages_search_url
    assert_response :success
  end

end
