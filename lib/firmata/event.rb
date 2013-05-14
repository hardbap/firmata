module Firmata
  class Event
    attr_reader :data, :name

    def initialize(name, *data)
      @name = name
      @data = *data
    end
  end
end
