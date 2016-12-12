#
# Cookbook Name:: omnibus_sensu
# Recipe:: default
#
# Copyright (c) 2016 Sensu, All Rights Reserved.

include_recipe "omnibus::default"

case node["platform_family"]
when "freebsd"
  package "git"
else
  include_recipe "git"
end

case node["platform_family"]
when "rhel"
  package "gpg"
  package "pygpgme"
end

gem_package "ffi-yajl" do
  gem_binary "/opt/omnibus-toolchain/bin/gem"
end

directory node["omnibus_sensu"]["project_dir"] do
  user node["omnibus"]["build_user"]
  group node["omnibus"]["build_user_group"]
  recursive true
  action :create
end

git node["omnibus_sensu"]["project_dir"] do
  repository 'https://github.com/sensu/sensu-omnibus.git'
  revision node["omnibus_sensu"]["project_revision"]
  user node["omnibus"]["build_user"]
  group node["omnibus"]["build_user_group"]
  action :sync
end

shared_env = {
  "SENSU_VERSION" => node["omnibus_sensu"]["build_version"],
  "BUILD_NUMBER" => node["omnibus_sensu"]["build_iteration"],
  "GPG_PASSPHRASE" => node["omnibus_sensu"]["gpg_passphrase"],
  "AWS_REGION" => node["omnibus_sensu"]["publishers"]["s3"]["region"],
  "AWS_S3_CACHE_BUCKET" => node["omnibus_sensu"]["publishers"]["s3"]["cache_bucket"],
  "AWS_ACCESS_KEY_ID" => node["omnibus_sensu"]["publishers"]["s3"]["access_key_id"],
  "AWS_SECRET_ACCESS_KEY" => node["omnibus_sensu"]["publishers"]["s3"]["secret_access_key"]
}

# pre-create omnibus execute resources which should be updated once omnibus_build lwrp executes
[
  "bundle exec omnibus build sensu --log-level internal --config /opt/sensu-omnibus/omnibus.rb ",
  "bundle install --without development --deployment"
].each do |omnibus_cmd_string|
  edit_resource(:execute, ["sensu: ", omnibus_cmd_string].join) do
    command ""
    live_stream true
  end
end

omnibus_build "sensu" do
  project_dir node["omnibus_sensu"]["project_dir"]
  log_level :internal
  build_user "root"
  environment shared_env
end

pkg_suffix_map = {
  [:ubuntu, :debian]                   => { :default => "deb" },
  [:redhat, :centos, :fedora, :suse]   => { :default => "rpm" },
  :solaris                             => { "5.10" => "solaris", "5.11" => "ips" },
  :aix                                 => { :default => "bff" },
  :freebsd                             => { :default => "txz" }
}

artifact_id = node["omnibus_sensu"]["build_version"] + node["omnibus_sensu"]["build_iteration"]

execute "publish_sensu_#{artifact_id}_s3" do
  command(
    <<-CODE.gsub(/^ {10}/, '')
          . #{::File.join(build_user_home, 'load-omnibus-toolchain.sh')}
          bundle exec omnibus publish s3 #{node["omnibus_sensu"]["publishers"]["s3"]["bucket_name"]} "pkg/sensu*.#{value_for_platform(pkg_suffix_map)}"
        CODE
  )
  cwd node["omnibus_sensu"]["project_dir"]
  user node["omnibus"]["build_user"]
  environment shared_env.merge!({
    'USER' => node["omnibus"]["build_user"],
    'USERNAME' => node["omnibus"]["build_user"],
    'LOGNAME' => node["omnibus"]["build_user"]
  })
  not_if { node["omnibus_sensu"]["publishers"]["s3"].any? {|k,v| v.nil? } }
end
