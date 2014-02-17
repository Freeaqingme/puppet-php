
define php::instance (
  $source           = '',
  $template         = '',
  $augeas           = false,
  $augeas_options   = {},
  $config_dir       = $::php::config_dir,
  $source_dir       = '',
  $source_dir_purge = false,
  $config_file      = $::php::config_file,
  $package          = $::php::package,
) {

  include php
  $bool_augeas=any2bool($augeas)
  $bool_source_dir_purge=any2bool($source_dir_purge)

  if ($source and $template) {
    fail ('PHP: cannot set both source and template')
  }
  if ($source and $bool_augeas) {
    fail ('PHP: cannot set both source and augeas')
  }
  if ($template and $bool_augeas) {
    fail ('PHP: cannot set both template and augeas')
  }

  $manage_file_source = $source ? {
    ''        => undef,
    default   => $source,
  }

  $manage_file_content = $template ? {
    ''        => undef,
    default   => template($template),
  }

  ### Managed resources
  if ! defined(Package[$package]) {
    $package_alias = $name ? {
      'default' => 'php',
      default   => "php-${name}"
    }

    package { $package_alias:
      ensure => $php::manage_package,
      name   => $package,
    }
  }

  file { "php.conf-${name}":
    ensure  => $::php::manage_file,
    path    => $config_file,
    mode    => $::php::config_file_mode,
    owner   => $::php::config_file_owner,
    group   => $::php::config_file_group,
    require => Package[$package],
    source  => $manage_file_source,
    content => $manage_file_content,
    replace => $::php::manage_file_replace,
    audit   => $::php::manage_audit,
  }

  # The whole php configuration directory can be recursively overriden
  if $php::source_dir {
    file { "php.dir-${name}":
      ensure  => directory,
      path    => $config_dir,
      require => Package[$package],
      source  => $source_dir,
      recurse => true,
      purge   => $bool_source_dir_purge,
      force   => $bool_source_dir_purge,
      replace => $::php::manage_file_replace,
      audit   => $::php::manage_audit,
    }
  }

  if $bool_augeas and $augeas_options != {} {
    $augeas_options.each |$k,$v| {
      php::augeas { "php-${name}-${k}":
        entry  => $k,
        value  => $v,
        target => $config_file
      }
    }
  }

}
