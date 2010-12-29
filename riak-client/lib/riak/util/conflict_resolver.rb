require 'riak'

module Riak
  module Util
    # Breaks down document conflicts into conflicting and nonconflicting data
    class ConflictResolver
      attr_reader :conflicting, :nonconflicting, :robject

      def initialize(robject)
        @robject = robject
        @conflicting = {}
        @nonconflicting = {}
        diff_siblings
      end

      private

      def diff_siblings
        robject.siblings.each do |sib|
          sib.data.each do |(key, value)|
            case @nonconflicting[key]
            when value
              next
            when nil
              if @conflicting[key]
                @conflicting[key] << value
              else
                @nonconflicting[key] = value
              end
            else # != value
              @conflicting[key] ||= []
              @conflicting[key] << @nonconflicting.delete(key)
              @conflicting[key] << value
            end
          end
        end
      end
    end
  end
end
