# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2014 6WIND S.A.

Name: dpdk-stable
Version: 17.11.10
Release: 1
Packager: packaging@6wind.com
URL: http://dpdk.org
Source: http://dpdk.org/browse/dpdk/snapshot/dpdk-%{version}.tar.xz

Summary: Data Plane Development Kit core
Group: System Environment/Libraries
License: BSD and LGPLv2 and GPLv2

ExclusiveArch: i686 x86_64 aarch64
%ifarch aarch64
%global machine armv8a
%global target arm64-stingray-linux-gcc
%global config arm64-stingray-linux-gcc
%else
%global machine default
%global target %{_arch}-%{machine}-linuxapp-gcc
%global config %{_arch}-native-linuxapp-gcc
%endif

BuildRequires: kernel-devel, kernel-headers, libpcap-devel
BuildRequires: doxygen, python3-sphinx

%description
DPDK core includes kernel modules, core libraries and tools.
testpmd application allows to test fast packet processing environments
on x86 platforms. For instance, it can be used to check that environment
can support fast path applications such as 6WINDGate, pktgen, rumptcpip, etc.
More libraries are available as extensions in other packages.

%package devel
Summary: Data Plane Development Kit for development
Requires: %{name}%{?_isa} = %{version}-%{release}
%description devel
DPDK devel is a set of makefiles, headers and examples
for fast packet processing on x86 platforms.

%prep
%setup -q

%build
make O=%{target} T=%{config} config
sed -ri 's,(RTE_MACHINE=).*,\1%{machine},' %{target}/.config
sed -ri 's,(RTE_APP_TEST=).*,\1n,'         %{target}/.config
sed -ri 's,(RTE_BUILD_SHARED_LIB=).*,\1y,' %{target}/.config
sed -ri 's,(RTE_NEXT_ABI=).*,\1n,'         %{target}/.config
sed -ri 's,(LIBRTE_VHOST=).*,\1y,'         %{target}/.config
sed -ri 's,(LIBRTE_PMD_PCAP=).*,\1y,'      %{target}/.config
make O=%{target} %{?_smp_mflags}

%install
rm -rf %{buildroot}
make install O=%{target} DESTDIR=%{buildroot} \
	prefix=%{_prefix} bindir=%{_bindir} sbindir=%{_sbindir} \
	includedir=%{_includedir}/dpdk libdir=%{_libdir} \
	datadir=%{_datadir}/dpdk docdir=%{_docdir}/dpdk

find %{buildroot}%{_datadir}/ -name "*.py" -exec \
sed -i -e 's|#!\s*/usr/bin/env python$|#!/usr/bin/python3|' {} +

%files
%dir %{_datadir}/dpdk
%{_datadir}/dpdk/usertools
/lib/modules/%(uname -r)/extra/*
%{_sbindir}/*
%{_bindir}/*
%{_libdir}/*

%files devel
%{_includedir}/dpdk
%{_datadir}/dpdk/mk
%{_datadir}/dpdk/buildtools
%{_datadir}/dpdk/%{target}
%{_datadir}/dpdk/examples

%post
/sbin/ldconfig
/sbin/depmod

%postun
/sbin/ldconfig
/sbin/depmod
