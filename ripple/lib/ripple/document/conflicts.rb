require 'ripple'

module Ripple
  module Document
    module Conflicts
      attr_accessor :conflicts

      def initialize(*args)
        super(*args)
        @conflicts = {}
      end
    end
  end
end
