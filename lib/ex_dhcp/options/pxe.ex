defmodule ExDhcp.Options.Pxe do
  @moduledoc """
  DHCP options for pxe booting
  """

  alias ExDhcp.Options
  import ExDhcp.Options.Macro

  @behaviour ExDhcp.Options.Api

  @tftp_server_name 66
  @bootfile_name 67
  @tftp_server 150
  @tftp_config 209
  @tftp_root 210

  options tftp_server_name:         :string,
          bootfile_name:            :string,
          tftp_server:              :ip,
          tftp_config:              :string,
          tftp_root:                :string

end
