NVCC:=nvcc
#GPU_PTX_ARCH:=compute_35
#GPU_PTX_ARCH:=compute_50
GPU_PTX_ARCH:=compute_52
#GPU_ARCHS?=sm_50,sm_61,sm_70,sm_80
GPU_ARCHS?=sm_52,sm_61,sm_70
#GPU_ARCHS?=sm_80
HOST_CFLAGS:=-Wall -Werror -fPIC -Wno-strict-aliasing
GPU_CFLAGS:=--gpu-code=$(GPU_ARCHS),$(GPU_PTX_ARCH) --gpu-architecture=$(GPU_PTX_ARCH)

# enable for profiling
#GPU_CFLAGS+=-lineinfo

# enable to see kernel register stats
#GPU_CFLAGS+=--ptxas-options=-v

CFLAGS_release:=-Icommon $(GPU_CFLAGS) -O3 -Xcompiler "$(HOST_CFLAGS)"
CFLAGS_debug:=$(CFLAGS_release) -g
CFLAGS:=$(CFLAGS_$V)
