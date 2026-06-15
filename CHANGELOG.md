cookbook-rb-monitor CHANGELOG
===============

## 0.7.0

  - Pablo Pérez
    - [c0b9667] Lint cookstyle
    - [55c9028] Allow sensor without ipaddress if is http agent
    - [6d88b5f] Add http agent nodes
    - [ffb939a] Fix comment formatting in rbmonitor_helpers.rb
    - [4a8301e] Add monitors if have the same name with different operations
    - [c55036e] Add endpoint enrichment as json

## 0.6.0

  - Miguel Negrón
    - [cf4a67b] Merge pull request #57 from redBorder/bugfix/#25275_campus_enrichment
  - manegron
    - [cf4a67b] Merge pull request #57 from redBorder/bugfix/#25275_campus_enrichment
    - [05339dc] add deployment, deployment_uuid, market and market_uuid to enrichment
  - flopez
    - [87beb8a] remove white line
    - [ef3b777] Add campus and campus_uiid to enrichment

## 0.5.7

  - manegron
    - [148d175] Monitor all memory services

## 0.5.6

  - manegron
    - [e5a0a1e] Add sensor_uuid

## 0.5.5

  - manegron
    - [2df5efe] Fix lint
    - [3bac9af] Add snmp, redfish and ipmi sensors

## 0.5.4

  - vimesa
    - [08da7e8] Fixed distribution of sensors in a cluster

## 0.5.3

  - ljblancoredborder
    - [8013b94] exception control made on an autorefactor of failing function
    - [2c92b83] adding proxy_nodes which is actually an array of nodes

## 0.5.2

  - José Navarro en redBorder
    - [7c30950] bugfix/22360_Monitor_shows_hostname_instead_of_sensor_name_with_redborder-proxy_sensor (#41)

## 0.5.1

  - jnavarrorb
    - [b063ea0] Remove executable permissions on non-executable files

## 0.5.0

  - vimesa
    - [1db563d] Add SNMP v3

## 0.4.0

  - Rafael Gomez
    - [d5cda80] Removing redborder-postgresql service

## 0.3.1

  - Rafael Gomez
    - [fdc3909] Update http_endpoint format to use cdomain for dynamic URL construction

## 0.2.0

  - Miguel Negrón
    - [8a15ff7] Update defautl community string

## 0.1.1

  - Miguel Negrón
    - [65a6f7a] Add pre and postun to clean the cookbook

## 0.1.0

  - Daniel Castro
    - [1af6337] fix add flow sensors to manager
    - [2994471] add function to register sensors in proxy

## 0.0.10

  - Miguel Negrón
    - [c827e71] Merge pull request #22 from redBorder/bugfix/18354_device_sensors_not_in_config

## 0.9.0

  - Miguel Alvarez
    - [d89a1db] Fix sensor_name array invalid
    - [c47a755] Fix sensor name for monitor

## 0.0.8

  - Miguel Negrón
    - [7e61f36] Improvement/fix lint (#18)

## 0.0.7

  - nilsver
    - [deeb69f] deep copy of service hash

## 0.0.6

  - JuanSheba
    - [fafc747] Change rb_http_mode to Normal

## 0.0.5

  - nilsver
    - [7d2cce2] add check if user modifies a service
    - [5ca8c0e] improved check if services is enabled
  - Miguel Negrón
    - [81c805a] Update README.md
    - [7ff5e4a] Update rpm.yml
    - [8a61273] Update metadata.rb

## 0.0.1
-----
- [ejimenez] - Initial skel
