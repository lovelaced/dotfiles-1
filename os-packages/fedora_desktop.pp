$yumgroups = [ "standard", "base-x" ] 

$userenv = [ "git", "zsh", "vim-minimal", "screen", "python-virtualenvwrapper", "vpnc" ]

$desktop = ['slim', 'rxvt-unicode-256color', 'xfce4-panel', 'xfce4-weather-plugin', 'xfce4-mailwatch-plugin', 'xfce4-datetime-plugin', 'xfce4-mpc-plugin', 'xfce4-timer-plugin', 'xfce4-icon-theme', 'xfce4-settings', 'gtk-chtheme', 'gtk2-engines', 'alsa-utils', 'compton', 'xscreensaver']

$fonts = ['terminus-fonts', 'google-droid-sans-fonts', 'google-droid-serif-fonts', 'google-droid-sans-mono-fonts', 'levien-inconsolata-fonts']

$apps = ['firefox', 'mpd', 'mpc', 'ncmpcpp']

define yumgroup($ensure = "present", $optional = false) {
   case $ensure {
      present,installed: {
         $pkg_types_arg = $optional ? {
            true => "--setopt=group_package_types=optional,default,mandatory",
            default => ""
         }
         exec { "Installing $name yum group":
            command => "/bin/yum -y groupinstall $pkg_types_arg $name",
            unless => "/bin/yum -y groupinstall $pkg_types_arg $name --downloadonly",
            timeout => 600,
         }
      }
   }
}


##
# creates a repo release file by downloading the $source
#
# $name: name of repository (creates ${name}.repo file)
# $source: URL to *-release rpm
define packages::repo_release ($source) {
        exec { $name:
                command =>"/bin/rpm -Uvh ${source}",
                creates => "/etc/yum.repos.d/${name}.repo",
        }
}

class bspwm_deps {
    # There is a good reason we only do the list of packages here and not all of libxcb. Install it all if you want to find out the reason..

	package { ['libxcb-devel', 'libxcb', 'xcb-util', 'xcb-util-devel', 'xcb-util-keysyms-devel']: ensure => "installed" }
    exec { "snag-f19-deps":
        command => "/bin/yum install -y --releasever=19 --nogpgcheck xcb-util-wm*",
        timeout => 600
    }
}

class box {
	include bspwm_deps

	yumgroup { $yumgroups: ensure => installed }

	package { [
		$userenv,
		$desktop,
		$fonts,
		$apps,
	]: ensure => "installed" }

    file { '/etc/systemd/system/default.target':
        ensure => link,
        target => '/usr/lib/systemd/system/graphical.target'
    }

    packages::repo_release { "rpmfusion-free": source => "http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-18.noarch.rpm", }
    packages::repo_release { "rpmfusion-nonfree": source => "http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-18.noarch.rpm", }
    package { [
            "rpmfusion-free-release",
            "rpmfusion-nonfree-release",
            ]:
            ensure => latest,
            require => [
                    Packages::Repo_release["rpmfusion-free"],
                    Packages::Repo_release["rpmfusion-nonfree"],
            ],
    }

    packages::repo_release { "infinality-repo": source => "http://www.infinality.net/fedora/linux/infinality-repo-1.0-1.noarch.rpm", }
    package { [ "freetype-infinality", "infinality-settings" ]:
        ensure => latest,
        require => [ Packages::Repo_release["infinality-repo"] ];
    }


}

include box
