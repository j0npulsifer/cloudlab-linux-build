ARCH=amd64
BUILD_DIR=build
KERNEL_MAJOR_VERSION=5
KERNEL_MINOR_VERSION=4
KERNEL_PATCH_VERSION=12
KERNEL_LOCAL_VERSION=-cloudlab
KERNEL_VERSION=$(KERNEL_MAJOR_VERSION).$(KERNEL_MINOR_VERSION).$(KERNEL_PATCH_VERSION)

.PHONY: all
all: help

.PHONY: kernel
kernel: verify-kernel genkconf build-kernel ## Downloads, verifies, configures, and starts a kernel build

.PHONY: verify-kernel
verify-kernel: ## Downloads and verifies $(KERNEL_VERSION)
	mkdir -p $(BUILD_DIR) && cd $(BUILD_DIR) && \
	wget -q --no-clobber https://cdn.kernel.org/pub/linux/kernel/v$(KERNEL_MAJOR_VERSION).x/linux-$(KERNEL_VERSION).tar.xz && \
	wget -q --no-clobber https://cdn.kernel.org/pub/linux/kernel/v$(KERNEL_MAJOR_VERSION).x/linux-$(KERNEL_VERSION).tar.sign && \
	gpg -q --locate-keys torvalds@kernel.org gregkh@kernel.org && \
	unxz -c linux-$(KERNEL_VERSION).tar.xz | gpg -q --verify linux-$(KERNEL_VERSION).tar.sign - && \
	tar -xaf linux-$(KERNEL_VERSION).tar.xz

.PHONY: genkconf
genkconf: ## copies a kconfig from /boot into the build dir and makes olddefconfig
	cd $(BUILD_DIR)/linux-$(KERNEL_VERSION) && \
	cp -v /boot/config-$(shell uname -r) .config && \
	make olddefconfig

.PHONY: build-kernel
build-kernel: ## Builds .debs of the kernel
	cd $(BUILD_DIR) && \
	make -j$(shell getconf _NPROCESSORS_ONLN) -C linux-$(KERNEL_VERSION)/ bindeb-pkg LOCALVERSION=$(KERNEL_LOCALVERSION)

.PHONY: clean
clean: ## Remove build artifacts
	rm -r $(BUILD_DIR)

.PHONY: help
help: ## ty jessfraz
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
