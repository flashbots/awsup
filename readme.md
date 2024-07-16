# AWS CLI Helper

AWS CLI Helper makes configuration easy and authentication very easy.

## Supported environments

- OS: `macOS`, `Ubuntu`
- Shell: `zsh`, `bash`
- OTP engine: `Yubikey`, `1password`, `manual`
- Vault engine: `macOS Keychain`, `file`

## Quick start

```bash
curl -sL https://raw.githubusercontent.com/0x416e746f6e/.aws/main/awsup.sh | bash
```

## The helper tool

Once you finish the setup process, you won't need to interact with the helper
tool `~/.aws/helper.sh`. However, if you need to make changes or redo your setup,
then you can use these arguments.

### Use an existing aws config

After setup, you can specify a custom config file. This lets private
data like roles and account IDs to be managed privately.

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
