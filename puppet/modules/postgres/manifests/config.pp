class postgres::config {

  file {

    "${postgres::params::home}/data/postgresql.conf":
      content => template("postgres/postgresql.conf.erb"),
      owner   => $postgres::params::user,
      group   => $postgres::params::group,
      notify  => Service["postgresql"],
      require => Exec["InitDB"];

    "${postgres::params::home}/data/pg_hba.conf":
      content => template("postgres/pg_hba.conf.erb"),
      owner   => "root",
      group   => "root",
      notify  => Service["postgresql"],
      require => Exec["InitDB"];
  }

  # wait 30 seconds (max) for postgresql daemon to accept connections and execute SQL commands
  exec { "wait-for-postgresql":
    environment => "PGCONNECT_TIMEOUT=5",
    command     => "for i in {1..6}; do /usr/bin/psql -U ${postgres::params::user} -h localhost -c 'select count(*) from pg_tables' >/dev/null 2>&1 || sleep 5; done",
    timeout     => 60,
    user        => $postgres::params::user,
    require     => Class["postgres::service"],
  }

  exec { "InitDB":
    command => $postgres::params::password ? {
      ""      => "/usr/bin/initdb ${postgres::params::home}//data -E UTF8",
      #horribale hack
      default => "echo \"${postgres::params::password}\" > /tmp/ps && /usr/bin/initdb ${postgres::params::home}/data --auth='password' --pwfile=/tmp/ps -E UTF8 ; rm -rf /tmp/ps"
    },
    user    => $postgres::params::user,
    creates  => "${postgres::params::home}/data/PG_VERSION",
  }

}