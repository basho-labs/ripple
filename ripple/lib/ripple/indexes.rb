require 'ripple/translation'
require 'active_support/concern'

module Ripple
  # Adds secondary-indexes to {Document} properties.
  module Indexes
    extend ActiveSupport::Concern

    module ClassMethods
      # Indexes defined on the document.
      def indexes
        @indexes ||= {}.with_indifferent_access
      end

      def property(key, type, options={})
        if indexed = options.delete(:index)
          indexes[key] = Index.new(key, type, indexed)
        end
        super
      end

      def index(key, type, &block)
        indexes[key] = Index.new(key, type, true, block)
      end
    end

    module InstanceMethods
      # Returns indexes in a form suitable for persisting to Riak.
      # @return [Hash] indexes for this document
      def indexes_for_persistence(prefix = '')
        Hash.new {|h,k| h[k] = Set.new }.tap do |indexes|
          # Add embedded associations' indexes
          self.class.embedded_associations.each do |association|
            documents = instance_variable_get(association.ivar)
            unless documents.nil?
              Array(documents).each do |doc|
                embedded_indexes = doc.indexes_for_persistence("#{association.name}_")
                indexes.merge!(embedded_indexes) do |_,original,new|
                  original.merge new
                end
              end
            end
          end

          # Add this document's indexes
          self.class.indexes.each do |key, index|

            if index.block.nil?
              index_value = index.to_index_value(self[key])
            else
              index_value =  instance_eval &index.block
            end
            index_value = Set[index_value] unless Enumerable === index_value
            indexes[prefix + index.index_key].merge index_value
          end
        end
      end
    end

    # Modifies the persistence chain to set indexes on the internal
    # {Riak::RObject} before saving.
    module DocumentMethods
      def update_robject
        robject.indexes = indexes_for_persistence
        super
      end
    end
  end

  # Represents a Secondary Index on a Document
  class Index
    include Translation
    attr_reader :key, :type, :block

    # Creates an index for a Document
    # @param [Symbol] key the attribute key
    # @param [Class] property_type the type of the associated property
    # @param ['bin', 'int'] index_type if given, the type of index
    def initialize(key, property_type, index_type=true, block = nil)
      @key, @type, @index, @block = key, property_type, index_type, block
    end


    # The key under which a value will be indexed
    def index_key
      "#{key}_#{index_type}"
    end

    # Converts an attribute to a value appropriate for storing in a
    # secondary index.
    # @param [Object] value a value of type {#type}
    # @return [String, Integer, Set] a value appropriate for storing
    #   in a secondary index
    def to_index_value(value)
      value.to_ripple_index(index_type)
    end

    # @return ["bin", "int", nil] the type of index used for this property
    # @raise [ArgumentError] if the type cannot be automatically determined
    def index_type
      @index_type ||= if /^bin|int$/ === @index
                        @index
                      else
                        determine_index_type or  raise ArgumentError, t('index_type_unknown', :property => @key, :type => @type.name)
                      end
    end

    private
    def determine_index_type
      if String == @type || @type < String
        'bin'
      elsif [Integer, Time, Date, ActiveSupport::TimeWithZone].any? {|t| t == @type || @type < t }
        'int'
      end
    end
  end
end
