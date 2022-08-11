require 'test_helper'

class AppsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get apps_create_url
    assert_response :success
  end

  test "should get show" do
    get apps_show_url
    assert_response :success
  end

  test "should get update" do
    get apps_update_url
    assert_response :success
  end

end
