require 'test_helper'

class CrawlersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
