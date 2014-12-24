class Socket::ConnectionsController < WebsocketRails::BaseController
  before_action :authorize

  def connected
    ship = current_user.current_ship

    ship.update_attribute :connected, true
    WebsocketRails[ship.currently_orbiting.channel_name].trigger :ship_arrived, ship
  end

  def disconnected
    ship = current_user.current_ship

    ship.update_attribute :connected, false
    WebsocketRails[ship.currently_orbiting.channel_name].trigger :ship_departed, ship
  end

  def authorize_private_channel
    # start out unauthorized. we'll switch this later on if everything checks out
    authorized = false

    # Faction.United Republic
    # StarSystem.Sol:Faction.United Republic
    ship = current_user.current_ship
    channel_name = message[:channel]

    # StarSystem.Sol:Faction.United Republic -> ['StarSystem.Sol', 'Faction.United Republic']
    channel_model_instances = channel_name.split(':').map do |channel_segment|
      # StarSystem.Sol -> ['StarSystem', 'Sol']
      split_channel_segment = channel_segment.split('.')

      # 'StarSystem' -> StarSystem
      channel_segment_class = Object.const_get split_channel_segment[0]

      # StarSystem.find_by(name: 'Sol')
      channel_segment_class.find_by(name: split_channel_segment[1])
    end

    if channel_model_instances.count == 2 && channel_model_instances.first.is_a?(StarSystem) && channel_model_instances.last.is_a?(Faction)
      # StarSystem.Sol:Faction.United Republic
      if ship.star_system == channel_model_instances.first && ship.faction == channel_model_instances.last
        authorized = true
      end
    elsif channel_model_instances.count == 1 && channel_model_instances.first.is_a?(Faction)
      # Faction.United Republic
      if ship.faction == channel_model_instances.first
        authorized = true
      end
    end

    if authorized
      accept_channel
    else
      deny_channel
    end
  end

private
  def authorize
    raise 'You must be logged in' if current_user.nil?
  end
end
