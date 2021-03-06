#gutenprint-locales libterm-readline-gnu-perl libterm-readline-perl-perl libpod-plainer-perl openprinting-ppds printer-driver-all foomatic-db-gutenprint libgd-tools 
%w{cups cups-bsd printer-driver-hpcups hplip hplip-cups hpijs-ppds}.each do |pkg|
  package pkg do
    options "--no-install-recommends "
    action :install
  end
end

execute "Setup LaserJet" do
  command "lpadmin -p npi_office -v socket://192.168.50.198 -m drv:///hpcups.drv/hp-laserjet_p4015dn.ppd -L 'NPI Front Office LaserJet P4015' -E"
  action :run
end

execute "Set Default Printer" do
  command "lpadmin -d npi_office"
  action :run
end