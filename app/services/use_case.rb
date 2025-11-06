# A pattern from a former colleague - the only reference I could find was in the wayback machine: https://web.archive.org/web/20150905160635/http://webuild.envato.com/blog/a-case-for-use-cases/
module UseCase
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  module ClassMethods
    # The perform method of a UseCase should always return itself
    def perform(*args)
      new(*args).tap { |use_case| use_case.perform }
    end
  end

  # implement all the steps required to complete this use case
  def perform
    raise NotImplementedError
  end

  # inside of perform, add errors if the use case did not succeed
  def success?
    errors.none?
  end
end
