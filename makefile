SCP=scp_bl2
TB=bl2
SOC=bl31
TOS=bl32
NS=bl33

LIST=root trusted_key non_trusted_key $(SCP) $(SOC) $(TOS) $(NS)

$(eval PEMS=$(foreach pe,${LIST},${pe}.pem))

TARGET_PEMS=
define GEN_RSA_KEY
TARGET_PEMS += $(1)
$(1):
	openssl genrsa -out $(1) 2048

endef

TARGET_PKS = 
define GEN_PK_KEY

$(eval DER=$(patsubst %.pem,%_pk.der,$(1)))
TARGET_PKS += $(DER)
$(DER):$(1)
	openssl rsa -in $(1) -inform PEM -pubout -outform DER -out $(DER)

endef 


define DUMP_PK

$(eval DER=$(patsubst %.pem,%_pk.der,$(1)))
$(eval DUMP=$(patsubst %.pem,%_pk_dump,$(1)))
$(DUMP):$(DER)
	od -t x1 -j 24 $(DER)

endef

TARGET_HASH = 
define GEN_PK_HASH

$(eval DER=$(patsubst %.pem,%_pk.der,$(1)))
$(eval HASH=$(patsubst %.pem,%_pk.sha256,$(1)))

TARGET_HASH += $(HASH)
$(HASH):$(DER)
	openssl rsa -pubin -inform DER -in $(DER) -outform der | openssl dgst -sha256 -binary > $(HASH)

endef


TARGET_CRT_PEM = 
define CRT_TO_PEM

$(eval CRT=$(patsubst %.pem,%.crt,$(1)))
$(eval PEM=$(patsubst %.pem,%.crt.pem,$(1)))

TARGET_CRT_PEM += $(PEM)

$(PEM):$(CRT)
	openssl x509 -inform DER -in $(CRT) -out $(PEM)

endef

$(eval $(foreach pe,${PEMS},$(call GEN_RSA_KEY,${pe})))
$(eval $(foreach pe,${PEMS},$(call GEN_PK_KEY,${pe})))
$(eval $(foreach pe,${PEMS},$(call DUMP_PK,${pe})))
$(eval $(foreach pe,${PEMS},$(call GEN_PK_HASH,${pe})))
$(eval $(foreach pe,${PEMS},$(call CRT_TO_PEM,${pe})))

rsa_key:$(TARGET_PEMS)

rsa_pk_key:$(TARGET_PKS)

rsa_hash:$(TARGET_HASH)

crt2pem:$(TARGET_CRT_PEM)

new_crt:
	./cert_create \
		--tfw-nvctr 1 \
		--ntfw-nvctr 2 \
		--key-alg rsa \
		--rot-key root.pem \
		--trusted-world-key trusted_key.pem \
		--non-trusted-world-key non_trusted_key.pem \
		--scp-fw           $(SCP).bin  \
		--scp-fw-key       $(SCP).pem  \
		--scp-fw-key-cert  $(SCP)_key.crt \
		--scp-fw-cert      $(SCP)_fw.crt \
		--soc-fw     	   $(SOC).bin \
		--soc-fw-key 	   $(SOC).pem  \
		--soc-fw-key-cert  $(SOC)_key.crt \
		--soc-fw-cert      $(SOC)_fw.crt \
		--tos-fw      	   $(TOS).bin \
		--tos-fw-key       $(TOS).pem  \
		--tos-fw-key-cert  $(TOS)_key.crt \
		--tos-fw-cert      $(TOS)_fw.crt \
		--nt-fw            $(NS).bin \
		--nt-fw-key        $(NS).pem   \
		--nt-fw-key-cert   $(NS)_key.crt \
		--nt-fw-cert       $(NS)_fw.crt \
		--tb-fw            $(TB).bin \
		--tb-fw-cert       $(TB)_fw.crt \
		--trusted-key-cert trusted_key.crt \

clean:
	rm -rf *.pem *.sha256 *.crt *.der
