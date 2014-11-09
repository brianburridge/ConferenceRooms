require 'test_helper'

class ConferenceRoomsControllerTest < ActionController::TestCase
  setup do
    @conference_room = conference_rooms(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_rooms)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_room" do
    assert_difference('ConferenceRoom.count') do
      post :create, conference_room: { description: @conference_room.description, location: @conference_room.location, name: @conference_room.name, photo: @conference_room.photo, sq_ft: @conference_room.sq_ft, user_id: @conference_room.user_id }
    end

    assert_redirected_to conference_room_path(assigns(:conference_room))
  end

  test "should show conference_room" do
    get :show, id: @conference_room
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_room
    assert_response :success
  end

  test "should update conference_room" do
    patch :update, id: @conference_room, conference_room: { description: @conference_room.description, location: @conference_room.location, name: @conference_room.name, photo: @conference_room.photo, sq_ft: @conference_room.sq_ft, user_id: @conference_room.user_id }
    assert_redirected_to conference_room_path(assigns(:conference_room))
  end

  test "should destroy conference_room" do
    assert_difference('ConferenceRoom.count', -1) do
      delete :destroy, id: @conference_room
    end

    assert_redirected_to conference_rooms_path
  end
end
