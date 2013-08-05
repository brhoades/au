my @mods = qw( Win32 Win32::MSI::DB Win32::IPConfig Win32::DriveInfo Win32::SystemInfo Win32::TieRegistry Win32::Exe Log::Log4perl YAML::Tiny Net::SMTP);

foreach $mod (@mods)
{
  system("cpan -i ".$mod);
}

exit 0;
