# == Schema Information
#
# Table name: conference_rooms
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  location    :string(255)
#  sq_ft       :integer
#  photo       :string(255)
#  description :text
#  user_id     :integer
#  created_at  :datetime
#  updated_at  :datetime
#

require 'test_helper'

class ConferenceRoomTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
