#!/bin/bash
#
#  Copyright 2020 Tim Aerts
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# dependencies: bash, gpg-agent, gpg, gpgconf, oathtool, coreutils, qrencode
# environment variables:
#
#   T_2FA_DIR
#   T_2FA_GPG_UID
#   T_2FA_GPG_KEY_ID
#   T_2FA_GPG_OPTS
#   T_2FA_TOTP_INTERVAL
#

function print_usage(){
    echo "usage: 2fa.sh <list|generate|add|remove|rename|qrsecret|asciisecret|setup> <account> [secret|account]"
}

T_2FA_DIR=${T_2FA_DIR:-~/.2fa}
b_dir="$T_2FA_DIR"
if [ ! -e "$b_dir" ]; then
    echo "no dir $b_dir"
    exit 2
fi

gpg_uid=$T_2FA_GPG_UID
gpg_kid=${T_2FA_GPG_KEY_ID:-${gpg_uid}}
if [ -z "$gpg_uid" ]; then
    echo no T_2FA_GPG_KEY_ID or T_2FA_GPG_UID env var set
    exit 6
fi

T_2FA_GPG_OPTS=${T_2FA_GPG_OPTS:-"--grab"}

umask 0077
chmod 0700 $b_dir $b_dir/*
chmod 0600 $b_dir/*/*
chmod -R go-rwx "$b_dir/.gnupg"
export GNUPGHOME="$b_dir/.gnupg"
r=$(gpg-connect-agent --homedir "$GNUPGHOME" --no-autostart /bye)
err=$?
if [ "$err" != 0 ]; then
    r=$(gpg-agent --sh --homedir "$GNUPGHOME" --daemon --default-cache-ttl 3600 $T_2FA_GPG_OPTS)
    err=$?
    if [ "$err" != 0 ]; then
        exit $err
    fi
fi

set -o pipefail

function generate_token(){
    account="$1"
    if [ -z "$account" ]; then
        print_usage
        return 5
    fi
    enc_file="$b_dir/$account/totp.key.gpg"
    if [ ! -e "$enc_file" ]; then
        echo "no such account"
        return 3
    fi
    secret_key_totp=$(gpg -q -u $gpg_kid -r "$gpg_uid" --decrypt $enc_file 2>/dev/null)
    if [ $? != 0 ]; then
        echo "problem decrypting"
        return 8
    fi
    # fetch date ourselves, that way we can show the timer
    TZ=UTC
    totp_interval=${T_2FA_TOTP_INTERVAL:-30}
    t_epoch=$(date +"%s")
    totp_time=$(date +"%Y-%m-%d %H:%M:%S" --date="@$t_epoch")
    expire_tm=$(date +"%S" --date="@$t_epoch")
    expire_tm=${expire_tm#0}
    expire_tm=$((totp_interval - expire_tm % totp_interval))
    code=$(oathtool -b --totp "$secret_key_totp" -s "$totp_interval" --now "$totp_time")
    if [ $? != 0 ]; then
        echo "problem making 2fa with oathtool"
        return $?
    fi
    printf "%s %02ss" $code $expire_tm
    return 0
}

function list_tokens(){
    sep="$1"
    if [ -z "$sep" ]; then
        sep="\n"
    fi
    if [ ! -e "$b_dir" ]; then
        return 0
    fi
    SAVEIFS=$IFS
    IFS=$(echo -en "\n\b")
    for f in $(ls $b_dir/*/totp.key.gpg|sort -fdi); do
        f=$(basename $(dirname "$f"))
        echo -n -e "$f$sep"
    done
    IFS=$SAVEIFS
}

function rename_token(){
    account="$1"
    rename_to="$2"
    if [ ! -e "$b_dir" ]; then
        return 0
    fi
    if [ -z "$account" -o -z "$rename_to" ]; then
        print_usage
        return 5
    fi
    if [ -e "$b_dir/$account" -a ! -e "$b_dir/$rename_to" ]; then
        mv "$b_dir/$account" "$b_dir/$rename_to"
        return $?
    else
        echo "not renaming $account to $rename_to"
        return 1
    fi
    return 0
}

function remove_token(){
    account="$1"
    if [ ! -e "$b_dir/$account/totp.key.gpg" ]; then
        return 0
    fi
    echo -n "do you really want to remove '$account'? (y/n) "
    read OK
    if [ "$OK" = 'Y' -o "$OK" = 'y' ]; then
        echo "removing '$account'"
        rm -f "$b_dir/$account/totp.key.gpg"
        rmdir "$b_dir/$account"
    fi
    return 0
}

function add_token(){
    account="$1"
    if [ -z "$account" ]; then
        print_usage
        return 5
    fi
    secret="$2"
    if [ -z "$secret" ]; then
        read -r -s -p "token: " secret
        if [ -z "$secret" ]; then
            print_usage
            return 5
        fi
    fi
    key_file="$b_dir/$account/totp.key"
    enc_file="$key_file.gpg"
    mkdir -p "$b_dir/$account"
    if [ -e "$enc_file" -o -e "$key_file" ]; then
        echo "account $account already there, check $enc_file or $key_file"
        return 4
    fi
    echo "$secret"|gpg -q -u $gpg_kid -r "$gpg_uid" --encrypt > "$key_file.gpg"
    return $?
}

function qr_secret(){
    account="$1"
    ascii_secret "$account" \
        |(read -r -s secret && echo "otpauth://totp/$account?secret=$secret") \
        |qrencode -o - -l H -t utf8 -r /dev/stdin 
    return $?
}

function ascii_secret(){
    account="$1"
    if [ -z "$account" ]; then
        print_usage
        return 5
    fi
    key_file="$b_dir/$account/totp.key"
    enc_file="$key_file.gpg"
    if [ ! -e "$enc_file" ]; then
        return 1
    fi
    gpg -q -u $gpg_kid -r "$gpg_uid" --decrypt $enc_file
    return $?
}

function setup_gpg(){
    echo "not yet implemented"
    return 1
}

what="$1"
shift
case "$what" in
    generate)
        if [ "$1" = '' ]; then
            IFS=""
            for a in $(list_tokens ""); do
                c=$(generate_token "$a")
                if [ $? != 0 ]; then
                    echo "$c"
                    exit $?;
                fi
                echo "$c      $a"
            done
        else
            a="$1"
            c=$(generate_token "$a")
            if [ $? != 0 ]; then
                echo "$c"
                exit $?;
            fi
            echo "$c      $a"
        fi
        ;;
    qrsecret)
        if [ "$1" = '' ]; then
            for a in $(list_tokens); do
                echo "$a"
                qr_secret "$a"
            done
        else
            qr_secret "$1"
        fi
        ;;
    asciisecret)
        if [ "$1" = '' ]; then
            for a in $(list_tokens); do
                echo "$a"
                ascii_secret "$a"
            done
        else
            ascii_secret "$1"
        fi
        ;;
    add)
        add_token "$1" "$2"
        ;;
    remove)
        remove_token "$1"
        ;;
    rename)
        rename_token "$1" "$2"
        ;;
    list)
        list_tokens
        ;;
    setup)
        setup_gpg
        ;;
    *)
        print_usage
        exit 0
        ;;
esac
exit $?
