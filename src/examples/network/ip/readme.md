# IPv4 subnet example

Carlos Une's subnet calculator prints the network, mask and endpoint addresses
for an IPv4 address and prefix. Prefixes from `/0` through `/32` are accepted.

Build VOC with `make` at the repository root, then:

```sh
make -C src/examples/network/ip
make -C src/examples/network/ip run ARGS='1.2.3.4/22'
```

The library is in [`src/ports/une/oberon-ip`](../../../ports/une/oberon-ip/readme.md).
It is licensed under [GPL-3.0](../../../ports/une/oberon-ip/COPYING).
