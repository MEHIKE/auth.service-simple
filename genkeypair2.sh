# The below command will create a file named 'server.pass.key' and place it in the same folder where the command is executed.
openssl genrsa -des3 -passout pass:$1 -out private.key 2048
# The below command will use the 'server.pass.key' file that just generated and create 'server.key'.
openssl rsa -passin pass:$1 -in private.key -out public.key

SIGNING_KEY=$(cat private.key)
VERIFICATION_KEY=$(cat public.key)

JWT_SIGNING_KEYS=$(cat <<EOF
jwt:
   token:
     signing-key: |
$(echo "$SIGNING_KEY" | awk '{printf "       %s\n", $0}')
      verification-key: |
$(echo "$VERIFICATION_KEY" | awk '{printf "       %s\n", $0}')
EOF
)

echo "$JWT_SIGNING_KEYS" > uaa_config.yml

#rm privkey.pem
#rm pubkey.pem

# The below command will ask you for information that would be included in the certificate. Since this is a self-signed certificate, there is no need to provide the 'challenge password' (to leave it blank, press enter).
openssl req -new -key public.key -out server.csr

openssl x509 -req -sha256 -extfile v3.ext -days 365 -in server.csr -signkey public.key -out server.crt
#subject=/C=EE/ST=HARJU/L=<locality>/O=<organization-name>/OU=<organization-unit-name>/CN=<common-name-probably-server-fqdn>/emailAddress=<email-address-provided-while-generating-csr>

openssl pkcs12 -export -name servercert -in server.crt -inkey public.key -out myp12keystore.p12

keytool -importkeystore -destkeystore keystore.jks -srckeystore myp12keystore.p12 -srcstoretype pkcs12 -alias servercert

