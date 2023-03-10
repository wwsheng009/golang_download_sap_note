package main

import (
	"crypto/tls"
	"io"
	"net/http"
	"os"
)

func main() {

	//
	// caCert, _ := ioutil.ReadFile("CA_CERT.PEM")
	// caCertPool := x509.NewCertPool()
	// caCertPool.AppendCertsFromPEM(caCert)

	cert, _ := tls.LoadX509KeyPair("CLIENT_CERT.PEM", "CLIENT_CERT_KEY.PEM")

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				// RootCAs:      caCertPool,
				Certificates: []tls.Certificate{cert},
			},
		},
	}

	// Make a request
	r, err := client.Get("https://apps.support.sap.com/sap/support/lp/notes/hcp/down4snote/down4snote.htm?iv_num=1648467&sap-language=EN")
	if err != nil {
		println(err.Error())
		return
	}
	defer r.Body.Close()

	bytes, err := io.ReadAll(r.Body)
	if err != nil {
		println(err.Error())
	}
	os.WriteFile("test.sar", bytes, os.ModePerm)

}
