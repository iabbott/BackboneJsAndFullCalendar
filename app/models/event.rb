class Event < ActiveRecord::Base
  attr_accessible :start, :end, :title, :color
end
