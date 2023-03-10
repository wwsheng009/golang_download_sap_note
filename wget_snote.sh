#!/bin/bash
# use to download the sap snote in batch mode

# usage,dowload sap note file in three mode
# download single
# wget_snote 0000012
# wget_snote -i 0000123

# download batch from file
# wget_snote -f list.txt

snote_list=""
snote_number=""

https_proxy="http://172.18.3.113:10809"

if command -v SAPCAR >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v wget >/dev/null 2>&1; then
    echo "SAPCAR and unzip and wget commands found"
else
    echo "SAPCAR or unzip or wget command not found, aborting script execution"
    exit 1
fi

if [ ! -d "sap_notes" ]; then
    mkdir sap_notes
fi

if [ ! -f "CLIENT_CERT_KEY.PEM" ] || [ ! "CA_CERT.PEM" ] || [ ! -f "CLIENT_CERT.PEM" ]; then
    echo "Certificate File does not exist, use openssl to generate the required files,you need input password"
    echo "openssl pkcs12 -in <SID>.pfx -clcerts -nokeys -out CLIENT_CERT.PEM"
    echo "openssl pkcs12 -in <SID>.pfx -nocerts -nodes -out CLIENT_CERT_KEY.PEM"
    echo "openssl pkcs12 -in <SID>.pfx -cacerts -nokeys -out CA_CERT.PEM"
fi

# download sap snote via http proxy
function download {
    local note_number="$1"
    if [ -z "$note_number" ]; then
        echo "please input snote number"
        return
    fi
    echo "Begin download sap_notes/${note_number}.SAR"
    wget --certificate=CLIENT_CERT.PEM --private-key=CLIENT_CERT_KEY.PEM --ca-certificate=CA_CERT.PEM -O "sap_notes/${note_number}.SAR" "https://apps.support.sap.com/sap/support/lp/notes/hcp/down4snote/down4snote.htm?iv_num=${note_number}&sap-language=EN" -e use_proxy=yes -e https_proxy=${https_proxy}

    SAPCAR -xvVf sap_notes/${note_number}.SAR -R sap_notes

    unzip sap_notes/*${note_number}*.ZIP -d sap_notes
}

while getopts ":f:i:" opt; do
    case ${opt} in
    f)
        snote_list="$OPTARG"
        ;;
    i)
        snote_number="$OPTARG"
        ;;
    \?)
        echo "Invalid option: -$OPTARG" 1>&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." 1>&2
        exit 1
        ;;
    esac
done

if [[ -z "$snote_number" ]] && [[ -z "$snote_list" ]]; then
    if [[ -n "$1" ]]; then
        snote_number="$1"
    else
        echo "No options specified. Using default values."
        snote_list="list.txt"
        snote_number=""
    fi
fi

echo "SAP Note List File: $snote_list"
echo "SAP Note: $snote_number"

if [[ -n "$snote_number" ]]; then
    download "$snote_number"
fi

if [[ -n "$snote_list" ]]; then
    if [ -f "$snote_list" ]; then
        filename="$snote_list"
        while read line; do
            download "$line"
        done <"$filename"
    else
        echo "Input snote_list $snote_list does not exist."
        exit 1
    fi

fi
