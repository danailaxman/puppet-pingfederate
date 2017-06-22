# Class pingfederate::server_settings
#
# Configure the server settings via the admin API. For documentation, see
# https://<server>:9999/pf-admin-api/api-docs
#
# This is not so easy as one would hope as many of the APIs require referencing a system-generated
# 'id' parameter that was created as the result of an earlier POST. These are written out of a file
# named *.id and then pulled in using 'pf-admin-api --subst id=filename.id'.
#
class pingfederate::server_settings inherits ::pingfederate {
  $pfapi = "${::pingfederate::install_dir}/local/bin/pf-admin-api"
  $etc = "${::pingfederate::install_dir}/local/etc"

  $ss = "serverSettings"
  file { "${etc}/${ss}.json":
    ensure   => 'present',
    mode     => 'a=r',
    owner    => $::pingfederate::owner,
    group    => $::pingfederate::group,
    content  => template("pingfederate/${ss}.json.erb"),
  } ~> 
  exec {"pf-admin-api PUT ${ss}":
    command     => "${pfapi} -m PUT -j ${etc}/${ss}.json -r ${etc}/${ss}.json.out ${ss}", # || rm -f ${ss}.json",
    refreshonly => true,
    user        => $::pingfederate::owner,
    logoutput   => true,
  }

  $pcv = "passwordCredentialValidators"
  file {"${etc}/${pcv}.json":
    ensure   => 'present',
    mode     => 'a=r',
    owner    => $::pingfederate::owner,
    group    => $::pingfederate::group,
    content  => template("pingfederate/${pcv}.json.erb"),
  } ~> 
  exec {"pf-admin-api POST ${pcv}":
    command     => "${pfapi} -m POST -j ${etc}/${pcv}.json -r ${etc}/${pcv}.json.out ${pcv}", # || rm -f ${pcv}.json",
    refreshonly => true,
    user        => $::pingfederate::owner,
    logoutput   => true,
  }


  # authenticationPolicyContracts link sp/idpConnections and oauth/authenticationPolicyContractMappings
  # by the 'id' that is the result of a POST. We identify our contacts by the 'name' which is used in
  # the JSON filename in order to find the 'id' to link by. oauth/authServerSettings comes first because
  # if defines the persistentGrantContract attributes that are referenced by these.

  $oas = "oauth/authServerSettings"
  $oasf = "oauth_authServerSettings"
  file {"${etc}/${oasf}.json":
    ensure   => 'present',
    mode     => 'a=r',
    owner    => $::pingfederate::owner,
    group    => $::pingfederate::group,
    content  => template("pingfederate/${oasf}.json.erb"),
  } ~> 
  exec {"pf-admin-api PUT ${oas}":
    command     => "${pfapi} -m PUT -j ${etc}/${oasf}.json -r ${etc}/${oasf}.json.out ${oas}", # || rm -f ${oasf}.json",
    refreshonly => true,
    user        => $::pingfederate::owner,
    logoutput   => true,
  }

  $apc = "authenticationPolicyContracts"
  notify { "checking for ::pingfederate::auth_policy_contract": }
  $::pingfederate::auth_policy_contract.each |$a| {
    notify { "apc: ${a}": }
    # need to check for existence of each key and replace missing values with defaults
    $b = deep_merge($::pingfederate::auth_policy_contract_default,$a)
    if !has_key($b,'name') {
      fail('auth_policy_contract must have a name')
    }
    $n=$b['name']
    $un=uriescape($n)
    file { "${etc}/${apc}_${un}.json":
      subscribe => Exec["pf-admin-api PUT ${oas}"],
      ensure    => 'present',
      mode      => 'a=r',
      owner     => $::pingfederate::owner,
      group     => $::pingfederate::group,
      content   => template("pingfederate/${apc}.json.erb"),
    } ~>
    exec { "pf-admin-api POST ${apc}_${un}":
      command     => "${pfapi} -m POST -j ${etc}/${apc}_${un}.json -r ${etc}/${apc}_${un}.json.out -i ${etc}/${apc}_${un}.id ${apc}", # || rm -f ${apc}_${un}.json,
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }
  
    $apcm = 'oauth/authenticationPolicyContractMappings'
    $apcmf = "oauth_authenticationPolicyContractMappings"

   
    file {"${etc}/${apcmf}_${un}.json":
      subscribe => [Exec["pf-admin-api PUT ${oas}"],Exec["pf-admin-api POST ${apc}_${un}"]],
      ensure  => present,
      mode    => 'a=r',
      owner   => $::pingfederate::owner,
      group   => $::pingfederate::group,
      content => template("pingfederate/${apcmf}.json.erb"),
    } ~>
    exec { "pf-admin-api POST ${apcm}_${un}":
      command     => "${pfapi} -m POST -j ${etc}/${apcmf}_${un}.json -s id=${etc}/${apc}_${un}.id -r ${etc}/${apcmf}_${un}.json.out -i ${etc}/${apcmf}_${un}.id ${apcm}", # || rm -f ${apcmf}_${un}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }
  } # end $::pingfederate::auth_policy_contract.each

  if $::pingfederate::oauth_svc_acc_tok_mgr_id {
    $atm = "oauth/accessTokenManagers"
    $atmf = "oauth_accessTokenManagers"
    Exec["pf-admin-api PUT ${oas}"] ~>
    file {"${etc}/${atmf}.json":
      ensure   => 'present',
      mode     => 'a=r',
      owner    => $::pingfederate::owner,
      group    => $::pingfederate::group,
      content  => template("pingfederate/${atmf}.json.erb"),
    } ~> 
    exec {"pf-admin-api POST ${atm}":
      command     => "${pfapi} -m POST -j ${etc}/${atmf}.json -r ${etc}/${atmf}.json.out ${atm}", # || rm -f ${atmf}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }
  } # endif $::pingfederate::oauth_svc_acc_tok_mgr_id

  if $::pingfederate::oauth_oidc_policy_id {
    $oip = "oauth/openIdConnect/policies"
    $oipf = "oauth_openIdConnect_policies"
    $ois = "oauth/openIdConnect/settings"
    $oisf = "oauth_openIdConnect_settings"
    file {"${etc}/${oipf}.json":
      ensure   => 'present',
      mode     => 'a=r',
      owner    => $::pingfederate::owner,
      group    => $::pingfederate::group,
      content  => template("pingfederate/${oipf}.json.erb"),
    } ~> 
    exec {"pf-admin-api POST ${oip}":
      command     => "${pfapi} -m POST -j ${etc}/${oipf}.json -r ${etc}/${oipf}.json.out ${oip}", # || rm -f ${oipf}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    } ~>
    file {"${etc}/${oisf}.json":
      ensure   => 'present',
      mode     => 'a=r',
      owner    => $::pingfederate::owner,
      group    => $::pingfederate::group,
      content  => template("pingfederate/${oisf}.json.erb"),
    } ~> 
    exec {"pf-admin-api PUT ${ois}":
      command     => "${pfapi} -m PUT -j ${etc}/${oisf}.json -r ${etc}/${oisf}.json.out ${ois}", # || rm -f ${oisf}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }
  } # endif $::pingfederate::oauth_oidc_policy_id

  # need to iterate, fill in defaults, use auth_policy_contract as filename component for $apc_*.id
  # move this up closer to the apc stuff?
  notify { "checking for ::pingfederate::saml2_idp": }
  $::pingfederate::saml2_idp.each |$a| {
    notify { "saml2_idp ${a}": }
    $spidp = 'sp/idpConnections'
    $spidpf = 'sp_idpConnections'
    $b = deep_merge($::pingfederate::saml2_idp_default,$a)
    $x509_string = regsubst($b['cert_content'],'\n','\\n','G')
    if !has_key($b,'auth_policy_contract') or !has_key($b,'name')
       or $b['auth_policy_contract'] == undef or $b['name'] == undef {
      fail("saml2_idp => 'name' and/or 'auth_policy_contract' is missing")
    }
    $n=$b['name']
    $un=uriescape($n)
    $an=$b['auth_policy_contract']
    $uan=uriescape($an)
    Exec["pf-admin-api POST ${apc}_${uan}"] ~>
    file {"${etc}/${spidpf}_${un}.json":
      ensure   => present,
      mode     => 'a=r',
      owner    => $::pingfederate::owner,
      group    => $::pingfederate::group,
      content  => template("pingfederate/${spidpf}.json.erb"),
    } ~>
    exec {"pf-admin-api POST ${spidp}_${un}":
      command     => "${pfapi} -m POST -j ${etc}/${spidpf}_${un}.json -s id=${etc}/${apc}_${uan}.id -r ${etc}/${spidpf}_${un}.json.out -i ${etc}/${spidpf}_${un}.id ${spidp}", # || rm -f ${spidpf}_${un}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }

    $oatsp = 'oauth/accessTokenMappings'
    $oatspf = 'oauth_accessTokenMappings_saml2'
    Exec["pf-admin-api POST ${apc}_${uan}"] ~>
    file {"${etc}/${oatspf}_${un}.json":
      ensure  => present,
      mode    => 'a=r',
      owner   => $::pingfederate::owner,
      group   => $::pingfederate::group,
      content => template("pingfederate/${oatspf}.json.erb"),
    } ~>
    exec {"pf-admin-api POST ${oatsp}/saml2_${un}":
      command     => "${pfapi} -m POST -j ${etc}/${oatspf}_${un}.json -s id=${etc}/${spidpf}_${un}.id -r ${etc}/${oatspf}_${un}.json.out -i ${etc}/${oatspf}_${un}.id ${oatsp}", # || rm -f ${oatspf}_${un}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }

  } #end $::pingfederate.saml2_idp.each

  ###
  # SOCIAL OAUTH ADAPTERS
  ###

  # TODO: make sure an adapter wasn't previously defined and is now removed. Removal happens
  # in the reverse order of addition!
  if str2bool($::pingfederate::facebook_adapter) {
    $fba = "idp/adapters"
    $fbaf = "idp_adapters_facebook"
    file {"${etc}/${fbaf}.json":
      ensure   => 'present',
      mode     => 'a=r',
      owner    => $::pingfederate::owner,
      group    => $::pingfederate::group,
      content  => template("pingfederate/${fbaf}.json.erb"),
    } ~> 
    exec {"pf-admin-api POST ${fbaf}":
      command     => "${pfapi} -m POST -j ${etc}/${fbaf}.json -r ${etc}/${fbaf}.json.out ${fba}", # || rm -f ${fbaf}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }

    $fbi = "oauth/idpAdapterMappings"
    $fbif = "oauth_idpAdapterMappings_facebook"
    file {"${etc}/${fbif}.json":
      require    => [
                     Exec["pf-admin-api POST ${fbaf}"], # need idp/apapters/Facebook
                     Exec["pf-admin-api POST ${atm}"],  # need oauth/accessTokenManagers/{id}
                     ],
      ensure     => 'present',
      mode       => 'a=r',
      owner      => $::pingfederate::owner,
      group      => $::pingfederate::group,
      content    => template("pingfederate/${fbif}.json.erb"),
    } ~> 
    exec {"pf-admin-api POST ${fbif}":
      command     => "${pfapi} -m POST -j ${etc}/${fbif}.json -r ${etc}/${fbif}.json.out ${fbi}", # || rm -f ${fbif}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }
    $oatfb = 'oauth/accessTokenMappings'
    $oatfbf = 'oauth_accessTokenMappings_facebook'
    Exec["pf-admin-api POST ${fbaf}"] ~>
    file {"${etc}/${oatfbf}.json":
      ensure   => 'present',
      mode     => 'a=r',
      owner    => $::pingfederate::owner,
      group    => $::pingfederate::group,
      content  => template("pingfederate/${oatfbf}.json.erb"),
    } ~> 
    exec {"pf-admin-api POST ${oatfb}/Facebook":
      command     => "${pfapi} -m POST -j ${etc}/${oatfbf}.json -r ${etc}/${oatfbf}.json.out -i ${etc}/${oatfbf}.id ${oatfb}", # || rm -f ${oatfbf}.json",
      refreshonly => true,
      user        => $::pingfederate::owner,
      logoutput   => true,
    }
  }    

  # TO DO: additional social adapters. Can probably parameterize and reuse the facebook stuff

}
