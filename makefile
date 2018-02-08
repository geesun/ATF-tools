ROOTPRIV=root_prvkey.pem
ROTPK_DER=root_pubkey.der
ROTPK_HASH=root_pubkey_sha256.bin

all:$(ROTPK_HASH)

#Generate the RSA-2048 private key
$(ROOTPRIV):
	@echo "Generate the RSA-2048 private key"
	openssl genrsa -out $@ 2048
	openssl genrsa -out trusted_key.pem 2048
	openssl genrsa -out non_trusted_key.pem 2048
	openssl genrsa -out scp_fw.pem 2048
	openssl genrsa -out soc_fw.pem 2048
	openssl genrsa -out tos_fw.pem 2048
	openssl genrsa -out non_trusted_fw.pem 2048

$(ROTPK_DER):$(ROOTPRIV)
	@echo "Extract public key from private key"
	openssl rsa -in $(ROOTPRIV) -inform PEM -pubout -outform DER -out $(ROTPK_DER)

$(ROTPK_HASH):$(ROTPK_DER)
	openssl rsa -pubin -inform DER -in $(ROTPK_DER) -outform der | openssl dgst -sha256 -binary > $@

dump_pk:
	openssl rsa -pubin -inform DER -in $(ROTPK_DER) -outform der |od -t x1 

clean:
	rm -rf $(ROOTPRIV) $(ROTPK_DER) $(ROTPK_HASH)
