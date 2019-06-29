defmodule DhcpTest.OptionsCodeTest do

  use ExUnit.Case

  @moduletag :basic_options

  alias ExDhcp.BasicOptions

  @subnet_mask              1
  @routers                  3
  @host_name                12
  @lease_time               51
  @message_type             53
  @parameter_request_list   55
  @client_ndi               94
  @uuid_guid                97
  @forcerenew_nonce_capable 145

  describe "encoding to binaries works" do
    test "for subnet_mask (ip example)" do
      assert <<@subnet_mask, 4, 10, 1, 10, 255>> ==
        BasicOptions.encode({:subnet_mask, {10, 1, 10, 255}})
      assert <<@subnet_mask, 4, 10, 1, 10, 255>> ==
        BasicOptions.encode({@subnet_mask, {10, 1, 10, 255}})
    end

    test "for routers (iplist example)" do
      assert <<@routers, 8, 10, 1, 10, 1, 10, 1, 11, 1>> ==
        BasicOptions.encode({:routers, [{10, 1, 10, 1}, {10, 1, 11, 1}]})
      assert <<@routers, 8, 10, 1, 10, 1, 10, 1, 11, 1>> ==
        BasicOptions.encode({@routers, [{10, 1, 10, 1}, {10, 1, 11, 1}]})
    end

    test "for host_name (string example)" do
      assert <<@host_name, 3, "foo">> == BasicOptions.encode({:host_name, "foo"})
      assert <<@host_name, 3, "foo">> == BasicOptions.encode({@host_name, "foo"})
    end

    test "for lease_time (integer example)" do
      assert <<@lease_time, 4, 100::32>> == BasicOptions.encode({:lease_time, 100})
      assert <<@lease_time, 4, 100::32>> == BasicOptions.encode({@lease_time, 100})
    end

    test "for message_type (message type example)" do
      assert <<@message_type, 1, 1>> == BasicOptions.encode({:message_type, :discover})
      assert <<@message_type, 1, 1>> == BasicOptions.encode({@message_type, <<1>>})
    end

    test "for parameter_request_list (parameter type example)" do
      assert <<@parameter_request_list, 4, 1, 2, 3, 4>> ==
        BasicOptions.encode({:parameter_request_list, [1, 2, 3, 4]})
      assert <<@parameter_request_list, 4, 1, 2, 3, 4>> ==
        BasicOptions.encode({@parameter_request_list, [1, 2, 3, 4]})
    end

    test "for client_ndi (client ndi type example)" do
      assert <<@client_ndi, 3, 1, 2, 3>> == BasicOptions.encode({:client_ndi, {1, 2, 3}})
      assert <<@client_ndi, 3, 1, 2, 3>> == BasicOptions.encode({@client_ndi, <<1, 2, 3>>})
    end

    test "for uuid-guuid (uuid type example)" do
      test_uuid = UUID.uuid4()
      test_uuid_bin = UUID.string_to_binary!(test_uuid)
      assert <<@uuid_guid, 16>> <> test_uuid_bin == BasicOptions.encode({:uuid_guid, test_uuid})
      assert <<@uuid_guid, 16>> <> test_uuid_bin == BasicOptions.encode({@uuid_guid, test_uuid_bin})
    end

    test "for forcerenew_nonce_capable (boolean type example)" do
      assert <<@forcerenew_nonce_capable, 1, 1>> ==
        BasicOptions.encode({:forcerenew_nonce_capable, true})
      assert <<@forcerenew_nonce_capable, 1, 1>> ==
        BasicOptions.encode({@forcerenew_nonce_capable, 1})
    end

    test "spurious tags are passed on" do
      pair = {:nonsense_atom, {:my, "funny", [:term]}}
      assert pair == BasicOptions.encode(pair)

      numpair = {254, "this is binary"}
      assert numpair == BasicOptions.encode(numpair)
    end
  end

  describe "decoding from binaries works" do
    test "for subnet_mask (ip example)" do
      assert {:subnet_mask, {10, 1, 10, 255}} ==
        BasicOptions.decode({@subnet_mask, <<10, 1, 10, 255>>})
    end

    test "for routers (iplist example)" do
      assert {:routers, [{10, 1, 10, 1}, {10, 1, 11, 1}]} ==
        BasicOptions.decode({@routers, <<10, 1, 10, 1, 10, 1, 11, 1>>})
    end

    test "for host_name (string example)" do
      assert {:host_name, "foo"} == BasicOptions.decode({@host_name, "foo"})
    end

    test "for lease_time (integer example)" do
      assert {:lease_time, 100} == BasicOptions.decode({@lease_time, <<100::32>>})
    end

    test "for message_type (message type example)" do
      assert {:message_type, :discover} == BasicOptions.decode({@message_type, <<1>>})
    end

    test "for parameter_request_list (parameter type example)" do
      assert {:parameter_request_list, [1, 2, 3, 4]} ==
        BasicOptions.decode({@parameter_request_list, <<1, 2, 3, 4>>})
    end

    test "for client_ndi (client ndi type example)" do
      assert {:client_ndi, {1, 2, 3}} == BasicOptions.decode({@client_ndi, <<1, 2, 3>>})
    end

    test "for forcerenew_nonce_capable (boolean type example)" do
      assert {:forcerenew_nonce_capable, true} ==
        BasicOptions.decode({@forcerenew_nonce_capable, <<1>>})
    end

    test "undecipherable tags are not deciphered" do
      numpair = {254, "this is binary"}
      assert numpair == BasicOptions.decode(numpair)
    end
  end
end
