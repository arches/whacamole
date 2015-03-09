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
      attr_reader :total_size, :swap_size

      def total_size=(size)
        @total_size = size.to_f if size
      end

      def swap_size=(size)
        @swap_size = size.to_f if size
      end
    end

    class DynoRestart < Event
    end
  end
end

