require "spec_helper"

require "chef/knife/rackspace_server_create"
require "chef/knife"

describe Chef::Knife::RackspaceServerCreate do
  let(:knife_rackspace_server_create) { Chef::Knife::RackspaceServerCreate.new }
  let(:rackspace_connection) { double(Fog::Compute) }
  let(:new_rackspace_server) { double }
  let(:rackspace_test_region) { "dfw" }
  let(:default_flavor) { double(id: "2", name: "512MB Standard Instance", ram: 512, disk: 20, vcpus: 1) }

  let(:rackspace_server_attribs) do
    {
      id: "1234",
      host_id: "1234",
      name: "my-new-rackspace-server",
      # flavor.name
      # image.name
      boot_image_id: "boot-image",
      # metadata.all
      config_drive: "drive",
      access_ipv4_address: "123.456.789.0",
      password: "password"
    }
  end

  before(:each) do
    # Stub these out to avoid unnecessary output
    allow(knife_rackspace_server_create).to receive(:msg_pair)
    allow(knife_rackspace_server_create).to receive(:puts)
    allow(knife_rackspace_server_create).to receive(:print)

    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_metadata).and_return({})
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_disk_config).and_return({})
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_config_drive).and_return(nil)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_ssh_keypair).and_return({})
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_user_data).and_return(nil)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_version)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_networks)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackconnect_v3_network_id)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:private_network)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:flavor)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:boot_volume_id)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:image)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:boot_volume_size)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:image).and_return("6c9f9665-ad2c-434b-9453-6607733ff7a4")
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_auth_url)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_username).and_return("knife-rackspace-test")
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_api_username)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_api_key).and_return("testing123")
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_region).and_return(rackspace_test_region)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:bootstrap_protocol)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackconnect_wait)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:rackspace_servicelevel_wait)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:server_create_timeout).and_return(1200)
    allow(knife_rackspace_server_create).to receive(:locate_config_value).with(:bootstrap_network).and_return("public")
    allow(knife_rackspace_server_create).to receive(:tcp_test_ssh).and_return(true)

    rackspace_server_attribs.each_pair do |attrib, value|
      allow(new_rackspace_server).to receive(attrib).and_return(value)
    end
    allow(new_rackspace_server).to receive_message_chain(:flavor).and_return(default_flavor)
    allow(new_rackspace_server).to receive_message_chain(:image).and_return(double(name: "my-image"))
    allow(new_rackspace_server).to receive_message_chain(:metadata).and_return(double(all: ""))
    allow(new_rackspace_server).to receive_message_chain(:addresses).and_return({network: "1.1.1.1"})

    allow(rackspace_connection).to receive_message_chain(:flavors, :get).and_return(default_flavor)

    knife_rackspace_server_create.config[:run_list] = ["role[base]"]
  end

  describe "run" do
    before do
      allow(Fog::Compute).to receive(:new).and_return(rackspace_connection)
      allow(rackspace_connection).to receive_message_chain(:servers, :new).and_return(new_rackspace_server)
      allow(new_rackspace_server).to receive(:save).with({networks: nil})
      allow(knife_rackspace_server_create).to receive(:bootstrap_for_node).and_return double("bootstrap", :run => true)
    end

    it "creates a Rackspace server" do
      expect(new_rackspace_server).to receive(:wait_for).and_return(true)
      knife_rackspace_server_create.run
    end
  end
end
