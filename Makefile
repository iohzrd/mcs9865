KDIR:=/lib/modules/$(shell  uname -r)/build/

DEBIAN_VERSION_FILE:=/etc/debian_version
DEBIAN_DISTRO:=$(wildcard $(DEBIAN_VERSION_FILE))
CURRENT=$(shell uname -r)
MAJORVERSION=$(shell uname -r | cut -d '.' -f 1)
MINORVERSION=$(shell uname -r | cut -d '.' -f 2)
SUBLEVEL=$(shell uname -r | cut -d '.' -f 3)

ifeq ($(MAJORVERSION),5)
MDIR=drivers/tty/serial
else
ifeq ($(MAJORVERSION),4)
MDIR=drivers/tty/serial
else
ifeq ($(MAJORVERSION),3)
MDIR=drivers/tty/serial/
else
ifeq ($(MAJORVERSION),2)
ifneq (,$(filter $(SUBLEVEL),38 39))
MDIR=drivers/tty/serial/
else
MDIR=drivers/serial/
endif
else
MDIR=drivers/serial/
endif
endif
endif
endif

obj-m +=mcs9865.o
obj-m +=mcs9865-isa.o

default:
	$(RM) *.mod.c *.o *.ko .*.cmd *.symvers
	$(MAKE) -C $(KDIR) M=$(PWD) modules
	gcc -pthread ioctl.c -o ioctl
load:
	insmod mcs9865.ko
unload:
	rmmod mcs9865

install:
	cp mcs9865.ko mcs9865-isa.ko /lib/modules/$(shell uname -r)/kernel/$(MDIR)
	depmod -A
	chmod +x mcs9865
	cp mcs9865 /etc/init.d/
ifeq ($(DEBIAN_DISTRO), $(DEBIAN_VERSION_FILE))
	ln -s /etc/init.d/mcs9865 /etc/rcS.d/S99mcs9865 || true
else
	ln -s /etc/init.d/mcs9865 /etc/rc3.d/S99mcs9865 || true
	ln -s /etc/init.d/mcs9865 /etc/rc5.d/S99mcs9865 || true
endif
	modprobe mcs9865
	modprobe mcs9865-isa

uninstall:
	modprobe -r mcs9865
	modprobe -r mcs9865-isa
	rm /lib/modules/$(shell uname -r)/kernel/$(MDIR)/mcs9865*
	depmod -A
	rm -f /etc/init.d/mcs9865
ifeq ($(DEBIAN_DISTRO), $(DEBIAN_VERSION_FILE))
	rm -f /etc/rcS.d/S99mcs9865
else
	rm -f /etc/rc3.d/S99mcs9865
	rm -f /etc/rc5.d/S99mcs9865
endif

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	$(RM) *.mod.c *.o *.ko .*.cmd *.symvers *.order *.markers
	$(RM) -r .tmp_versions
	rm -f ioctl
