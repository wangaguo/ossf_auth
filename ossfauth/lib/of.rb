
class OpenFoundryError < RuntimeError; end

class SignUpDuplicationError < OpenFoundryError 
end

require 'yaml'

module OpenFoundry
  module Message
    def self.included(base)
      base.extend(ClassMethods)
    end

    # for deliver ACTIONS, like CRUD
    ACTIONS = {
      :create => 'create',
      :update => 'update',
      :delete => 'delete'}.freeze

    # for delivery TYPE, like object type
    TYPES = {
      :project => 'project',
      :user => 'user' ,
      :function => 'function'}.freeze

    module ClassMethods
      include ActiveMessaging::MessageSender

      publishes_to :ossf_msg
      def send_msg(type, action, data)
        publish(:ossf_msg,
          "#{YAML::dump({'type' => type, 'action' => action, 'data' => data})}"
        )
      end
    end
  end
end

ActiveRecord::Base.send(:include, OpenFoundry::Message)

