module Plover
  
  class Server
    
    attr_accessor :server_id, :name, :dns_name, :role, :name, :internal_ip, :flavor_id, :image_id
    
    def initialize(connection, server_specs)
      @connection = connection
      @specs = server_specs
      @fog_server = nil
      set_attributes(@specs)
    end
    
    def boot
      if running?
        false
      else
        @fog_server = @connection.servers.create(:flavor_id => flavor_id, :image_id => image_id, :groups => ["default", "ssh"], :user_data => File.read("config/cloud-config.txt"))
        true
      end
    end
    
    def running?
      ec2_server.state == "running" unless ec2_server.nil?
    end
    
    def state
      if ec2_server.nil?
        "not found"
      else
        ec2_server.state
      end
    end
    
    def shutdown
      ec2_server.destroy
    end
    
    def update_once_running
      @fog_server.wait_for { ready? }
      set_attributes_from_server_object(@fog_server)
    end
    
    def update_from_running
      set_attributes_from_server_object(ec2_server)
    end
    
    private
    
    def set_attributes(server_hash)
      server_hash.each do |spec, value|
        send(spec.to_s+"=", value)
      end
    end
    
    def set_attributes_from_server_object(server)
      hash = {:server_id => server.id, :flavor_id => server.flavor_id, :image_id => server.image_id, :dns_name => server.dns_name, :internal_ip => server.ip_address}
      set_attributes(hash)
    end
    
    def ec2_server
      @connection.servers.get(server_id)
    end
    
  end
  
end