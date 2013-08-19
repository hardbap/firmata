module Firmata
  class Event
    attr_reader :data, :name

    def initialize(name, *data)
      @name = name.to_sym
      @data = *data
    end
  end
end
