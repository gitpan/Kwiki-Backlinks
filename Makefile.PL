use inc::Module::Install;

name('Kwiki-Backlinks');
abstract('Keep and display a simple database of backlinks within a wiki');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Backlinks.pm');
license('perl');

requires('Kwiki' => 0.37,
         'Kwiki::Test' => 0,
         'Kwiki::UserPreferences' => 0);

check_nmake();

&WriteAll();
