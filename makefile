SCP=scp
TB=bl2
SOC=bl31
TOS=bl32
NS=bl33

RSA_KEYS=root trusted non_trusted $(SCP) $(SOC) $(TOS) $(NS)
CERTIFICATES=trusted $(SCP) $(SOC) $(TOS) $(NS)

TARGET_PEMS=
define GEN_RSA_KEY
$(eval PEM=$(1).pem)
TARGET_PEMS += $(1).pem
$(PEM):
	openssl genrsa -out $(PEM) 2048

endef

TARGET_PKS = 
define GEN_PK_KEY
$(eval PEM=$(1).pem)
$(eval DER=$(1)_pk.der)
TARGET_PKS += $(DER)
$(DER):$(PEM)
	openssl rsa -in $(PEM) -inform PEM -pubout -outform DER -out $(DER)

endef 


define DUMP_PK
$(eval DER=$(1)_pk.der)
$(eval DUMP=$(1)_pk.dump)
$(DUMP):$(DER)
	od -t x1 -j 24 $(DER)

endef

TARGET_HASH = 
define GEN_PK_HASH
$(eval DER=$(1)_pk.der)
$(eval HASH=$(1)_pk.sha256)

TARGET_HASH += $(HASH)
$(HASH):$(DER)
	openssl rsa -pubin -inform DER -in $(DER) -outform der | openssl dgst -sha256 -binary > $(HASH)

endef


TARGET_CRT_PEM = 
define CRT_TO_PEM

$(eval CRT=$(1)_key.crt)
$(eval PEM=$(1)_key.crt.pem)
$(eval FW_CRT=$(1)_fw.crt)
$(eval FW_PEM=$(1)_fw.crt.pem)

TARGET_CRT_PEM += $(PEM) 
ifneq ($(1), trusted)
TARGET_CRT_PEM += $(FW_PEM)
endif

$(PEM):$(CRT)
	openssl x509 -inform DER -in $(CRT) -out $(PEM)

ifneq ($(1), trusted)
$(FW_PEM):$(FW_CRT)
	openssl x509 -inform DER -in $(FW_CRT) -out $(FW_PEM)
endif 

endef

$(eval $(foreach pe,${RSA_KEYS},$(call GEN_RSA_KEY,${pe})))
$(eval $(foreach pe,${RSA_KEYS},$(call GEN_PK_KEY,${pe})))
$(eval $(foreach pe,${RSA_KEYS},$(call DUMP_PK,${pe})))
$(eval $(foreach pe,${RSA_KEYS},$(call GEN_PK_HASH,${pe})))
$(eval $(foreach pe,${CERTIFICATES},$(call CRT_TO_PEM,${pe})))

rsa_key:$(TARGET_PEMS)

rsa_pk_key:$(TARGET_PKS)

rsa_hash:$(TARGET_HASH)

crt2pem:$(TARGET_CRT_PEM)

new_crt:$(TARGET_PEMS)
	./cert_create \
		--tfw-nvctr 1 \
		--ntfw-nvctr 2 \
		--key-alg rsa \
		--rot-key root.pem \
		--trusted-world-key trusted.pem \
		--non-trusted-world-key non_trusted.pem \
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


all: $(TARGET_PEMS)

clean:
	rm -rf *.pem *.sha256 *.crt *.der
