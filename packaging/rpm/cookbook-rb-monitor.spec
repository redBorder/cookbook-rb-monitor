Name: cookbook-rb-monitor
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: redborder monitor cookbook to install and configure monitorization system on redborder environment. 

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-rb-monitor
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/rb-monitor
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/rb-monitor/
chmod -R 0755 %{buildroot}/var/chef/cookbooks/rb-monitor
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/rb-monitor/README.md

%pre
if [ -d /var/chef/cookbooks/rb-monitor ]; then
    rm -rf /var/chef/cookbooks/rb-monitor
fi

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload rbmonitor'
  ;;
esac

%postun
# Deletes directory when uninstall the package
if [ "$1" = 0 ] && [ -d /var/chef/cookbooks/rb-monitor ]; then
  rm -rf /var/chef/cookbooks/rb-monitor
fi

%files
%defattr(0755,root,root)
/var/chef/cookbooks/rb-monitor
%defattr(0644,root,root)
/var/chef/cookbooks/rb-monitor/README.md

%doc

%changelog
* Thu Oct 10 2024 Miguel Negrón <manegron@redborder.com>
- Add pre and postun

* Wed Jan 23 2024 David Vanhoucke <dvanhoucke@redborder.com>
- Fix redborder-monitor

* Mon Dec 18 2023 Miguel Álvarez <malvarez@redborder.com>
- Remove logstash from monitor stats

* Tue Apr 18 2023 Luis J. Blanco <ljblanco@redborder.com>
- clean templates with helpers

* Tue Oct 18 2016 Alberto Rodríguez <arodriguez@redborder.com>
- first spec version
