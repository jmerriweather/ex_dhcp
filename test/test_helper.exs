# if you'd like to test the dhcp server in action against
# a running vm inside of KVM/QEMU, you can run the task
# `mix test --only libvirt`
# note that several checks will be run to make sure this
# integration test works as expected.

ExUnit.configure(exclude: [:libvirt])
Code.require_file("test/behaviour/common_dhcp.exs")
ExUnit.start()
