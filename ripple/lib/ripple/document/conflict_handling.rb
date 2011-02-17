require 'ripple'

module Ripple
  module Document
    module ConflictHandling
      private

      def handle_conflict(robject)
        raise NotImplementedError.new(t('not_implemented',
                                      :method  => 'handle_conflict(robject)',
                                      :context => 'allow_mult'))
      end
    end
  end
end
