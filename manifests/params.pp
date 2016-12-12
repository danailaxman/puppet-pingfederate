# default values
class pingfederate::params {
  $install_dir                         = '/opt/pingfederate'
  $package_list                        = 'pingfederate-server'
  $package_ensure                      = 'installed'
  $package_java_list                   = undef
  $package_java_ensure                 = 'installed'
  $package_java_redhat                 = 'java-1.8.0-oracle'
  $package_java_centos                 = 'jre1.8.0_111'
  $facebook_adapter                    = false
  $facebook_package_list               = 'pingfederate-facebook-adapter'
  $facebook_package_ensure             = 'installed'
  $google_adapter                      = false
  $google_package_list                 = 'pingfederate-google-adapter'
  $google_package_ensure               = 'installed'
  $linkedin_adapter                    = false
  $linkedin_package_list               = 'pingfederate-linkedin-adapter'
  $linkedin_package_ensure             = 'installed'
  $twitter_adapter                     = false
  $twitter_package_list                = 'pingfederate-twitter-adapter'
  $twitter_package_ensure              = 'installed'
  $windowslive_adapter                 = false
  $windowslive_package_list            = 'pingfederate-windowslive-adapter'
  $windowslive_package_ensure          = 'installed'
  $service_name                        = 'pingfederate'
  $service_ensure                      = true
  $license_content                     = undef
  $license_file                        = undef
  $owner                               = 'pingfederate'
  $group                               = 'pingfederate'
  # run.properties defaults
  # see https://documentation.pingidentity.com/pingfederate/pf82/index.shtml#adminGuide/concept/changingConfigurationParameters.html
  # and /opt/pingfederate-$PF_VERSION/pingfederate/bin/run.properties
  $admin_https_port                    = 9999
  $admin_hostname                      = undef
  $console_bind_address                = '0.0.0.0'
  $console_title                       = 'PingFederate'
  $console_session_timeout             = 30
  $console_login_mode                  = 'multiple'
  $console_authentication              = 'native'
  $admin_api_authentication            = 'native'
  $http_port                           = -1
  $https_port                          = 9031
  $secondary_https_port                = -1
  $engine_bind_address                 = '0.0.0.0'
  $monitor_bind_address                = '0.0.0.0'
  $log_eventdetail                     = false
  $heartbeat_system_monitoring         = false
  $operational_mode                    = 'STANDALONE'
  $cluster_node_index                  = 0
  $cluster_auth_pwd                    = undef
  $cluster_encrypt                     = false
  $cluster_bind_address                = 'NON_LOOPBACK'
  $cluster_bind_port                   = 7600
  $cluster_failure_detection_bind_port = 7700
  $cluster_transport_protocol          = 'tcp'
  $cluster_mcast_group_address         = '239.16.96.69'
  $cluster_mcast_group_port            = 7601
  $cluster_tcp_discovery_initial_hosts = undef
  $cluster_diagnostics_enabled         = false
  $cluster_diagnostics_addr            = '224.0.75.75'
  $cluster_diagnostics_port            = 7500
  $adm_user                            = 'Administrator'
  $adm_pass                            = 'p@Ssw0rd'
  $adm_hash                            = 'k1H1o2jc66sgkDjJKq85Sr22QNk143S20oR2Yyt2kqo.5Cu-mnqB.2'
  $adm_api_baseURL                     = "https://${facts['fqdn']}:${admin_https_port}/pf-admin-api/v1"
  $saml2_local_entityID                = "${facts['hostname']}-ping:urn:saml1"
  $saml2_local_baseURL                 = "https://${facts['fqdn']}:${https_port}"
  $cors_allowedOrigins                 = '*'
  $cors_allowedMethods                 = 'GET,OPTIONS,POST'
  $cors_filter_mapping                 = '/*'
  $ognl_expressions_enable             = true
  $oauth_jdbc_url                      = undef
}
