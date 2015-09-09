require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Mysql < Base
        SUPER_USER_SAFE = true

        MYSQL_APT_CONFIG_VERSION = '0.3.7'

        def after_prepare
          sh.fold 'mysql' do
            sh.echo "Installing MySQL version #{mysql_version}", ansi: :yellow
            sh.cmd "service mysql stop", sudo: true
            sh.cmd "wget http://dev.mysql.com/get/#{config_file}"
            sh.cmd "dpkg -i #{config_file}", sudo: true
            sh.cmd "apt-get update -qq", assert: false, sudo: true
            sh.cmd "echo #{config_seed} | sudo tee /var/cache/local/preseeding/mysql-apt-config.seed", echo: false
            sh.cmd "debconf-set-selections /var/cache/local/preseeding/mysql-apt-config.seed", sudo: true
            sh.cmd "dpkg-reconfigure mysql-apt-config", sudo: true
            sh.cmd "apt-get install -o Dpkg::Options::='--force-confnew' components.join(' ')}", sudo: true, echo: true, timing: true
            sh.echo "Starting MySQL v#{mysql_version}", ansi: :yellow
            sh.cmd "service mysql start", sudo: true, assert: false, echo: true, timing: true
            sh.cmd "mysql --version", assert: false, echo: true
          end
        end

        private
        def mysql_version
          config.to_s.shellescape
        end

        def config_file
          "mysql-apt-config_#{MYSQL_APT_CONFIG_VERSION}-1ubuntu$(lsb_release -rs)_all.deb"
        end

        def components
          %w(
            mysql-common
            mysql-community-client
            mysql-client
            libmysqlclient18
            libmysqlclient-dev
            mysql-community-server
            mysql-server
          )
        end

        def config_seed
          template = <<-EOF
mysql-apt-config mysql-apt-config/enable-repo select mysql-#{mysql_version}
mysql-apt-config mysql-apt-config/select-server select mysql-#{mysql_version}
          EOF
        end
      end
    end
  end
end