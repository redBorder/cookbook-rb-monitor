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

%post

%files
%defattr(0755,root,root)
/var/chef/cookbooks/rb-monitor
%defattr(0644,root,root)
/var/chef/cookbooks/rb-monitor/README.md

%doc

%changelog
* Tue Oct 18 2016 Alberto Rodríguez <arodriguez@redborder.com> - 1.0.0-1
- first spec version
