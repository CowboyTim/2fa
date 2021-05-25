# DESCRIPTION

This is a bash script and wrapper for TOTP codes, using oathtool where the
shared secret is encrypted using gpg. 

This 2fa script can be used to manage multiple TOTP accounts easily and there
is a feature to export the shared secrets as a qr code so they can be imported
by any third party qr code authenticator app. Default behaviour can be changed
by environment variables.

The files needed for gpg are saved in a separate directory compared to the
normal $HOME/.gpg directory to not interfere with the user's already configured
gpg setup.

# ARGUMENTS

* add <account> <secret>
    This adds a totp account with the secret

* generate \[<account>\]
    This generates the totp code for an account (or all if the account is omitted)

* list
    This lists the totp accounts

* rename <old account> <new account>
    This renames a totp account

* asciisecret \[<account>\]
    This prints the account's secret as ascii on command line

* qrsecret \[<account>\]
    This prints the account's secret as a qr code in ascii in the terminal for
    import in a thirdparty authenticator app

* remove <account>
    This removes an totp account

* setup
    This is not yet implemented

# ENVIRONMENT

* T_2FA_DIR
* T_2FA_GPG_UID
* T_2FA_GPG_KEY_ID
* T_2FA_TOTP_INTERVAL

# INSTALLATION

The script needs bash, gpg, oathtool, qrencode and coreutils. Note that the
qrencode dependency is optional when the export feature isn't needed

