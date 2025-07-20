PROJECT := garmingotchi
DEVICE  := instinct3solar45mm

SRC_DIR   := source
INC_DIR   := include
RES_DIR   := resources
BIN_DIR   := bin
KEYS_DIR  := keys

PROGRAM  := $(BIN_DIR)/$(PROJECT).prg
DEV_KEY  := $(KEYS_DIR)/developer_key.der
MANIFEST := ./manifest.xml
JUNGLE   := ./monkey.jungle

SOURCES   := $(shell find $(SRC_DIR) -name *.mc)
OBJECTS   := $(patsubst %.mc,$(BIN_DIR)/%.mc,$(SOURCES))
RESOURCES := $(shell find $(RES_DIR) $(RES_DIR)-$(DEVICE) -type f)

CPP_FLAGS := -I$(INC_DIR) -P

all: key app

key: $(DEV_KEY)

app: $(PROGRAM)

sim: $(PROGRAM)
	monkeydo $(PROGRAM) $(DEVICE)

ciq:
	connectiq &

$(BIN_DIR)/%.prg: $(OBJECTS) $(RESOURCES) $(MANIFEST) $(JUNGLE) $(DEV_KEY)
	@mkdir -p $(dir $@)
	monkeyc -d $(DEVICE) -f $(JUNGLE) -o $@ -y $(DEV_KEY) -w -r -k

.PRECIOUS: $(BIN_DIR)/%.mc
$(BIN_DIR)/%.mc: %.mc
	@mkdir -p $(dir $@)
	cpp $(CPP_FLAGS) $< -o $@

$(KEYS_DIR)/%.der: $(KEYS_DIR)/%.PEM
	openssl pkcs8 -topk8 -inform PEM -outform DER -in $< -out $@ -nocrypt

$(KEYS_DIR)/%.pem:
	@mkdir -p $(dir $@)
	openssl genrsa -out $@ 4096

clean:
	rm -rf $(BIN_DIR)

.PHONY: all key app sim ciq clean
