ARCH=amd64
BASE_URL=https://partner-images.canonical.com/core/bionic/current
BASE_PACKAGE=ubuntu-bionic-core-cloudimg-$(ARCH)
BASE_TARBALL=$(BASE_PACKAGE)-root.tar.gz
BUILD_DIR=build
KERNEL_MAJOR_VERSION=5
KERNEL_MINOR_VERSION=4
KERNEL_PATCH_VERSION=11
KERNEL_VERSION=$(KERNEL_MAJOR_VERSION).$(KERNEL_MINOR_VERSION).$(KERNEL_PATCH_VERSION)
KERNEL_LOCALVERSION=-cloudlab

REGISTRY=gcr.io
PROJECT=trusted-builds
IMAGE_NAME=ubuntu-1804-base
FULL_IMAGE_URL=$(REGISTRY)/$(PROJECT)/$(IMAGE_NAME)

# http://keyserver.ubuntu.com/pks/lookup?search=0xD2EB44626FDDC30B513D5BB71A5D6C4C7DB87C81&op=vindex
# Type bits/keyID     cr. time   exp time   key expir
# pub  4096R/7DB87C81 2009-09-15
# uid UEC Image Automatic Signing Key <cdimage@ubuntu.com>
GPG_KEY=D2EB44626FDDC30B513D5BB71A5D6C4C7DB87C81

.PHONY: all
all: help ## Prints help message

.PHONY: update-baseimage
update-baseimage: verify-baseimage ## Updates the baseimage manifest and serial
	stat -c %y $(BUILD_DIR)/$(BASE_TARBALL) | awk '{print $$1}' | tr -d \- > $(CURDIR)/current && \
	cp -v $(BUILD_DIR)/$(BASE_PACKAGE).manifest $(CURDIR)

.PHONY: verify-baseimage
verify-baseimage: ## Download and verify the latest base image
	mkdir -p $(BUILD_DIR) && cd $(BUILD_DIR) && \
	for file in SHA256SUMS SHA256SUMS.gpg $(BASE_PACKAGE).manifest $(BASE_TARBALL); do \
		wget -q --no-clobber -O $$file $(BASE_URL)/$$file ; \
	done && \
	gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys $(GPG_KEY) && \
	gpg --batch --verify SHA256SUMS.gpg SHA256SUMS && \
	sha256sum --ignore-missing -c SHA256SUMS

.PHONY: download-kernel
download-kernel: ## Downloads and verifies KERNEL_VERSION
	mkdir -p $(BUILD_DIR) && cd $(BUILD_DIR) && \
	wget -q --no-clobber https://cdn.kernel.org/pub/linux/kernel/v$(KERNEL_MAJOR_VERSION).x/linux-$(KERNEL_VERSION).tar.xz && \
	wget -q --no-clobber https://cdn.kernel.org/pub/linux/kernel/v$(KERNEL_MAJOR_VERSION).x/linux-$(KERNEL_VERSION).tar.sign && \
	gpg -q --locate-keys torvalds@kernel.org gregkh@kernel.org && \
	unxz -kf linux-$(KERNEL_VERSION).tar.xz && gpg -q --verify linux-$(KERNEL_VERSION).tar.sign && \
	tar -xf linux-$(KERNEL_VERSION).tar

.PHONY: genkconf
genkconf: ## copies a kconfig from /boot into the build dir
	cd $(BUILD_DIR)/linux-$(KERNEL_VERSION) && \
	make olddefconfig

.PHONY: build-kernel
build-kernel: ## Builds .debs of the kernel
	cd $(BUILD_DIR) && \
	make -j$(shell getconf _NPROCESSORS_ONLN) -C linux-$(KERNEL_VERSION)/ bindeb-pkg LOCALVERSION=$(KERNEL_LOCALVERSION)

.PHONY: push
push: verify-baseimage build-local ## Tag and push new Dockerfile
	docker tag $(FULL_IMAGE_URL) $(FULL_IMAGE_URL):$(RELEASE) && \
	docker push $(FULL_IMAGE_URL):$(RELEASE)

.PHONY: build-local
build-local: update-baseimage ## Build Docker container locally (assumes docker present)
	cp -v $(CURDIR)/images/base.Dockerfile $(BUILD_DIR)/Dockerfile && \
	docker build -t $(FULL_IMAGE_URL) $(BUILD_DIR)

.PHONY: clean
clean: ## Remove build artifacts
	rm  -rv $(BUILD_DIR)/* && rmdir -v $(BUILD_DIR) || echo "$(BUILD_DIR) does not exist. Nothing to do."

.PHONY: help
help: ## ty jessfraz
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
