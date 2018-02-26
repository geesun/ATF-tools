CROSS_COMPILE=/toolchains/aarch64/bin/aarch64-linux-gnu- \
              make V=1 BL33=../linaro-1707-64/output/fvp/components/fvp/uboot.bin PLAT=fvp DEBUG=1  \
              all fip 

