module Whacamole
  module Events
    class Event
      attr_accessor :process

      def initialize(attributes={})
        attributes.each do |k,v|
          self.send("#{k}=", v)
        end
      end
    end

    class DynoSize < Event
      attr_accessor :units
      attr_reader :size

      def size=(size)
        @size = size.to_f
      end
    end

    class DynoRestart < Event
    end
  end
end

