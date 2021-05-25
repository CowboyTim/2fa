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

## ARGUMENTS

* add <&lt;account>&gt; <&lt;secret>&gt;

This adds a totp account with the secret

* generate [<&lt;account>&gt;]

This generates the totp code for an account (or all if the account is omitted)

* list

This lists the totp accounts

* rename <&lt;old account>&gt; <&lt;new account>&gt;

This renames a totp account

* asciisecret [<&lt;account>&gt;]

This prints the account's secret as ascii on command line

* qrsecret [<&lt;account>&gt;]

This prints the account's secret as a qr code in ascii in the terminal for
import in a thirdparty authenticator app

* remove <&lt;account>&gt;

This removes an totp account

* setup

This is not yet implemented

## ENVIRONMENT

* T\_2FA\_DIR

* T\_2FA\_GPG\_UID

* T\_2FA\_GPG\_KEY\_ID

* T\_2FA\_TOTP\_INTERVAL

## INSTALLATION

The script needs gpg, oathtool and qrencode (omitting the obvious bash and
coreutils). Note that the qrencode dependency is optional when the export
feature isn't needed.

To install those on e.g. a debian or linux mint:

    apt install gpg oathtool qrencode
