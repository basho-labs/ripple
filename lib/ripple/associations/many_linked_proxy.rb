require 'ripple/associations/proxy'
require 'ripple/associations/many'
require 'ripple/associations/linked'

module Ripple
  module Associations
    class ManyLinkedProxy < Proxy
      include Many
      include Linked

      def <<(value)
        if loaded?
          new_target = @target.concat(Array.wrap(value))
          replace new_target
        else
          @reflection.verify_type!([value], @owner)
          @owner.robject.links << value.to_link(@reflection.link_tag)
          appended_documents << value
          @keys = nil
        end

        self
      end

      def delete(value)
        load_target
        @target.delete(value)
        replace @target
        self
      end

      def reset
        @appended_documents = nil
        super
      end

      def loaded_documents
        (super + appended_documents).uniq
      end

      protected

      def find_target
        robjs = robjects

        robjs.delete_if do |robj|
          appended_documents.any? do |doc|
            doc.key == robj.key &&
              doc.class.bucket_name == robj.bucket.name
          end
        end

        docs = appended_documents + robjs.map {|robj| klass.send(:instantiate, robj) }
        read_repair_association docs, klass.bucket_name
        docs
      end

      def read_repair_association(validated_docs, tagged_as)
        matched_keys = validated_docs.map{|o| o.key}
        @owner.robject.links.delete_if { |link|
          ! (matched_keys.include?(link.key) ||
             link.tag != tagged_as)
        }
      end

      def appended_documents
        @appended_documents ||= []
      end
    end
  end
end
