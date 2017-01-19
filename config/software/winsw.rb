name "winsw"
default_version "2.0.0"

source url: "https://github.com/kohsuke/winsw/releases/download/winsw-v#{version}/WinSW.NET4.exe"

version "2.0.0" do
  source md5: "3e085789b572149b73e727a48581dd72"
end

relative_path "winsw-v#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  bin_dir = File.join(install_dir, "bin")

  if windows?
    # framework = windows_arch_i386? ? "Framework" : "Framework64"
    # mkdir(bin_dir)
    # command_options = "/target:Clean;Build /p:Configuration=Release /p:PostBuildEvent="
    # command("MSBuild.exe src/winsw.sln #{command_options}", env: env)
    # copy("bin/Release/winsw.exe", "#{bin_dir}/winsw.exe")
    copy("WinSW.NET4.exe", "#{bin_dir}/winsw.exe")
  end
end

# files_dir = "#{Dir.pwd}\\assets\\msi\\files".gsub("/", '\\')

# copy("bin/Release/winsw.exe", )
# t.install_commands << "mkdir #{install_prefix}\\bin"
# t.install_commands << "copy bin\\Release\\winsw.exe #{install_prefix}\\bin\\sensu-client.exe"
# t.install_commands << "copy #{files_dir}\\sensu-client.exe.config #{install_prefix}\\bin\\sensu-client.exe.config"