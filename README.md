## DESCRIPTION

This is a bash script and wrapper for TOTP codes, using oathtool where the
shared secret is encrypted using gpg. 

This 2fa script can be used to manage multiple TOTP accounts easily and there
is a feature to export the shared secrets as a qr code so they can be imported
by any third party qr code authenticator app. Default behaviour can be changed
by environment variables.

The files needed for gpg are saved in a separate directory compared to the
normal $HOME/.gpg directory to not interfere with the user's already configured
gpg setup.

When a request is made to make a totp code with "generate", a connection is
made to the gpg-agent running for the T_2FA_DIR. If this agens is not running,
a new gpg agent is started. This gpg agent is used to decrypt the totp secret
and will ask for a passphrase. The agent is kept running so subsequent totp
code generate requests don't need a passphrase entry each time, the cache TTL
is set to 3600.

## ARGUMENTS

* `add \<account\> \<secret\>`

This adds a totp account with the secret

* `generate [\<account\>]`

This generates the totp code for an account (or all if the account is omitted)

* `list`

This lists the totp accounts

* `rename \<old account\> \<new account\>`

This renames a totp account

* `asciisecret [\<account\>]`

This prints the account's secret as ascii on command line

* `qrsecret [\<account\>]`

This prints the account's secret as a qr code in ascii in the terminal for
import in a thirdparty authenticator app

* `remove \<account\>`

This removes an totp account

* `setup`

This is not yet implemented

## ENVIRONMENT

* T\_2FA\_DIR

This is the base directory. This is the directory where all of the secrets are
stored. This is default ~/.2fa

* T\_2FA\_GPG\_UID

This is the gpg uid to use. This is e.g. your email address.

* T\_2FA\_GPG\_KEY\_ID

This is the gpg key id to use, if this is not specified, the T\_2FA\_GPG\_UID
is used instead.

* T\_2FA\_TOTP\_INTERVAL

This is the TOTP interval, this is default 30 seconds and is probably better
not touched.

## INSTALLATION

The script needs gpg, oathtool and qrencode (omitting the obvious bash and
coreutils). Note that the qrencode dependency is optional when the export
feature isn't needed.

To install those on e.g. a debian or linux mint:

    apt-get install gpg oathtool qrencode
