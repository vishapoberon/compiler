# ULM Unix smoke tests

Build the tests with an installed VOC compiler:

```sh
voc -M testUnixFiles.Mod
voc -M testUnixTerminals.Mod
voc -M testUnixTerminalExit.Mod
```

Run the file and explicit terminal-close tests normally from this directory:

```sh
./testUnixFiles
./testUnixTerminals
```

The terminal tests require standard input and output to refer to the same
terminal. To verify restoration during program shutdown:

```sh
before=$(stty -g)
./testUnixTerminalExit
test "$before" = "$(stty -g)"
```

`testUnixFiles` leaves `ulmUnixFiles.test` in the current directory.
