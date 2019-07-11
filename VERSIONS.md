# ExDhcp Versions

## 0.1

### 0.1.1

- initial release

### 0.1.2

- add ip binding option
- clean up DHCP packet pattern matching
- warn if conntrack is activated on some linux distros (e.g. **Ubuntu 18.04**)
- warn about stray UDP packets coming your way

### 0.1.3 (proposed)

- clean up tests to use `:gen_udp.open(0, ...)` semantics
- instrument an `info` method.

### 0.2 (proposed)

- create `init/4` to allow more information to be put into state
