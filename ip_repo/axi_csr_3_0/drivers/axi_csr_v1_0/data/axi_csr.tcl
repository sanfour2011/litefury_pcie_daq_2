

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "axi_csr" "NUM_INSTANCES" "DEVICE_ID"  "C_axi_csr_BASEADDR" "C_axi_csr_HIGHADDR"
}
