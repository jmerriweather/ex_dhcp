defmodule ExDhcp.Options.Basic do

  @moduledoc false

  alias ExDhcp.Options
  import ExDhcp.Options.Macro

  @behaviour ExDhcp.Options.Api

  # Message types
  @dhcp_discover 1
  @dhcp_offer    2
  @dhcp_request  3
  @dhcp_decline  4
  @dhcp_ack      5
  @dhcp_nak      6
  @dhcp_release  7
  @dhcp_inform   8

  # DHCP options
  @subnet_mask                 1
  @routers                     3
  @domain_name_servers         6
  @host_name                   12
  @broadcast_address           28
  @requested_address           50
  @lease_time                  51
  @message_type                53
  @server                      54
  @parameter_request_list      55
  @message                     56
  @max_message_size            57
  @renewal_time                58
  @rebinding_time              59
  @vendor_class_identifier     60
  @client_identifier           61
  @client_system               93
  @client_ndi                  94
  @uuid_guid                   97
  @forcerenew_nonce_capable    145

  options subnet_mask:              :ip,
          routers:                  :iplist,
          domain_name_servers:      :iplist,
          host_name:                :string,
          broadcast_address:        :ip,
          requested_address:        :ip,
          lease_time:               :integer,
          message_type:             :message_type,
          server:                   :ip,
          parameter_request_list:   :parameter_list,
          message:                  :string,
          max_message_size:         :integer,
          renewal_time:             :integer,
          rebinding_time:           :integer,
          vendor_class_identifier:  :string,
          client_identifier:        :string,
          client_system:            :string,
          client_ndi:               :client_ndi,
          uuid_guid:                :uuid,
          forcerenew_nonce_capable: :boolean

  #############################################################################
  ## message type translations

  @type message_types():: :discover | :offer | :request | :decline | :ack |
                          :nak | :release | :inform

  @spec decode_message_type(binary) :: message_types | byte
  def decode_message_type(<<@dhcp_discover>>), do: :discover
  def decode_message_type(<<@dhcp_offer>>), do: :offer
  def decode_message_type(<<@dhcp_request>>), do: :request
  def decode_message_type(<<@dhcp_decline>>), do: :decline
  def decode_message_type(<<@dhcp_ack>>), do: :ack
  def decode_message_type(<<@dhcp_nak>>), do: :nak
  def decode_message_type(<<@dhcp_release>>), do: :release
  def decode_message_type(<<@dhcp_inform>>), do: :inform
  def decode_message_type(other), do: other

  @spec encode_message_type(message_types | binary) :: binary
  def encode_message_type(:discover), do: <<@dhcp_discover>>
  def encode_message_type(:offer), do: <<@dhcp_offer>>
  def encode_message_type(:request), do: <<@dhcp_request>>
  def encode_message_type(:decline), do: <<@dhcp_decline>>
  def encode_message_type(:ack), do: <<@dhcp_ack>>
  def encode_message_type(:nak), do: <<@dhcp_nak>>
  def encode_message_type(:release), do: <<@dhcp_release>>
  def encode_message_type(:inform), do: <<@dhcp_inform>>
  def encode_message_type(other), do: other

  @spec decode_parameter_list(binary) :: list
  def decode_parameter_list(bin), do: :erlang.binary_to_list(bin)
  @spec encode_parameter_list(list) :: binary
  def encode_parameter_list(lst), do: :erlang.list_to_binary(lst)

  @type client_ndi_type :: {byte, byte, byte}

  @spec decode_client_ndi(binary) :: client_ndi_type
  def decode_client_ndi(<<a, b, c>>), do: {a, b, c}
  @spec encode_client_ndi(client_ndi_type | binary) :: binary
  def encode_client_ndi({a, b, c}), do: <<a, b, c>>
  def encode_client_ndi(bin), do: bin
end
