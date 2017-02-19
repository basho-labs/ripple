require 'ripple/associations/proxy'
require 'ripple/associations/one'

module Ripple
  module Associations
    class OneInverseProxy < Proxy
      include One

      def replace(value)
        @reflection.verify_type!(value, owner)

        if value
          assign_key(value)
        else
          assign_key(nil)
        end

        @target = value
        loaded
      end

      protected

      def assign_key(value)
        value.send("#{key_name}=", owner.key)
      end

      # @return String representing the inverse key
      def key_name
        return @foreign_key unless @foreign_key.blank?

        @foreign_key = @reflection.options[:of_key] # The key used to build the association from the other object

        unless @foreign_key
          foreign_association = klass.associations[@reflection.options[:of].to_s]
          @foreign_key = foreign_association && foreign_association.options[:foreign_key]
        end

        @foreign_key || "#{owner.class.to_s.downcase.singularize}_key"
      end

      def find_target
        klass.find_by_index(key_name, owner.key).first unless owner.key.blank?
      end
    end
  end
end
