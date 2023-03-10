# download SAP note using golang


## make the ca files use the personal 

Obtaining the SAP Passport

Convert the certificate from the PKCS#12 format to PEM

```sh
openssl pkcs12 -in SID.pfx -clcerts -nokeys -out CLIENT_CERT.PEM
openssl pkcs12 -in SID.pfx -nocerts -nodes -out CLIENT_CERT_KEY.PEM
openssl pkcs12 -in SID.pfx -cacerts -nokeys -out CA_CERT.PEM
```

## Download SAP node need the Mutual authentication




