json.array!(@conference_rooms) do |conference_room|
  json.extract! conference_room, :id, :name, :location, :sq_ft, :photo, :description, :user_id
  json.url conference_room_url(conference_room, format: :json)
end
