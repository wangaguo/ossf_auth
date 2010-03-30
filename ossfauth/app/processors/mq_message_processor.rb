class MqMessageProcessor < ApplicationProcessor

  subscribes_to :ossf_message

  def on_message(message)
    logger.debug "MqMessageProcessor received: " + message
  end
end
