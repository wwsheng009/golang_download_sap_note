#!/bin/bash

openssl pkcs12 -in SID.pfx -clcerts -nokeys -out CLIENT_CERT.PEM
openssl pkcs12 -in SID.pfx -nocerts -nodes -out CLIENT_CERT_KEY.PEM
openssl pkcs12 -in SID.pfx -cacerts -nokeys -out CA_CERT.PEM

wget --certificate=CLIENT_CERT.PEM --private-key=CLIENT_CERT_KEY.PEM --ca-certificate=CA_CERT.PEM -O 1648467.SAR 'https://apps.support.sap.com/sap/support/lp/notes/hcp/down4snote/down4snote.htm?iv_num=1648467&sap-language=EN'

#should work
wget --certificate=CLIENT_CERT.PEM --private-key=CLIENT_CERT_KEY.PEM -O 1648467.SAR 'https://apps.support.sap.com/sap/support/lp/notes/hcp/down4snote/down4snote.htm?iv_num=1648467&sap-language=EN'
