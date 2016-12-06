class Poll
  class BoothAssignment < ActiveRecord::Base
    belongs_to :booth
    belongs_to :poll

    has_many :officer_assignments, class_name: "Poll::OfficerAssignment", dependent: :destroy
    has_many :officers, through: :officer_assignments
  end
end
