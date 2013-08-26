class torquebox {

  $tb_version   = "3.0.0.beta2"
  $tb_home      = "/opt/torquebox"
  $tb_current   = "${tb_home}/current"
  $tb_download  = "http://torquebox.org/release/org/torquebox/torquebox-dist/${tb_version}/torquebox-dist-${tb_version}-bin.zip"

  package { ["openjdk-7-jre", "unzip", "git"]:
    ensure => present
  }

  user { "torquebox":
    ensure     => present,
    managehome => true,
    system     => true
  }

  file { $tb_home:
    ensure    => directory,
    owner     => torquebox,
    group     => torquebox,
    recurse   => true,
    require   => User[torquebox]
  }

  exec { "download_tb":
    command => "wget -O /tmp/torquebox.zip ${tb_download}",
    path    => $path,
    creates => "/tmp/torquebox.zip",
    unless  => "ls ${tb_home} | grep torquebox-${tb_version}",
    require => [Package["openjdk-7-jre"]]
  }

  exec { "unpack_tb":
    command => "unzip /tmp/torquebox.zip -d ${tb_home}",
    user    => torquebox,
    path    => $path,
    creates => "${tb_home}/torquebox-${tb_version}",
    require => [Exec["download_tb"], Package[unzip], User[torquebox]]
  }

  file { $tb_current:
    ensure  => link,
    target  => "${tb_home}/torquebox-${tb_version}",
    require => Exec["unpack_tb"]
  }

  file { "/etc/profile.d/torquebox.sh":
    ensure    => file,
    content   => template("torquebox/torquebox.sh.erb"),
    require   => File[$tb_current]
  }

  file { "/etc/default/jboss-as":
    ensure    => file,
    content   => template("torquebox/jboss-as.conf.erb"),
    require   => File["/etc/profile.d/torquebox.sh"],
  }

  file { "/etc/init.d/jboss-as-standalone":
    ensure    => file,
    mode      => 0755,
    content   => template("torquebox/jboss-as-standalone.erb"),
    require   => File["/etc/default/jboss-as"]
  }

  service { "jboss-as-standalone":
    enable    => true,
    ensure    => running,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['/etc/default/jboss-as'],
    require   => [
       File["/etc/default/jboss-as"],
       File["/etc/init.d/jboss-as-standalone"]
     ]
  }

}

