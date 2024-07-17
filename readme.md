# awsup

`awsup` is a helper utility for the [aws cli](https://aws.amazon.com/cli/) that aims to make configuration easy and authentication very easy.

## Quick start

```bash
curl -sL awsup.sh | bash
```

## Supported environments

- OS: `macOS`, `Ubuntu`
- Shell: `zsh`, `bash`
- OTP engine: `Yubikey`, `1password`, `manual`
- Vault engine: `macOS Keychain`, `file`

## The helper tool

Once you finish the setup process, you won't need to interact with the helper tool `~/.aws/helper.sh`. However, if you need to make changes or redo your setup, then you can use these arguments.

### Use an existing aws config

After setup, you can specify a custom config file. This lets private data like roles and account IDs to be managed privately.

```bash
~/.aws/helper.sh --custom-config /path/to/config # File
~/.aws/helper.sh --custom-config https://config  # URL
```

### Redo the setup

```bash
~/.aws/helper.sh --setup
```

### Manually trigger a login

```bash
~/.aws/helper.sh --login
```

### Delete login lock

```bash
~/.aws/helper.sh --delete-lock
```

## Giants

- [0x416e746f6e](https://github.com/0x416e746f6e/.aws)
- [rustup](https://github.com/rust-lang/rustup)
- [suaveup](https://github.com/flashbots/suave-geth/tree/main/suave/suaveup)
