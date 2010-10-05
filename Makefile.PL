use inc::Module::Install;

name 'DNode';
all_from 'lib/DNode.pm';
license 'perl';

requires 'AnyEvent' => '0.00';

WriteAll;
