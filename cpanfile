# cpanfile for App-Devel-Todo
# Modern dependency specification for Perl projects

requires 'perl', '5.016';

# Core dependencies
requires 'Getopt::Long', '2.24';
requires 'YAML::XS', '0';
requires 'Cwd', '0';
requires 'File::Basename', '0';
requires 'Carp', '0';
requires 'Scalar::Util', '0';

# Object system (migrating from Mouse to Moo)
requires 'Moo', '2.000000';
requires 'Type::Tiny', '1.000000';
requires 'Types::Standard', '1.000000';

# Testing
on 'test' => sub {
  requires 'Test::More', '0.96';
  requires 'Test::Output', '0';
  requires 'File::Temp', '0.22';
  requires 'Test::Exception', '0.43';
  requires 'Test::Warnings', '0.026';
};

# Development tools
on 'develop' => sub {
  requires 'Perl::Critic', '1.140';
  requires 'Perl::Tidy', '20220217';
  requires 'Devel::Cover', '1.36';
  requires 'Pod::Coverage', '0.23';
  requires 'Test::Pod', '1.52';
  requires 'Test::Pod::Coverage', '1.10';
};

# Build system
on 'configure' => sub {
  requires 'Module::Build::Tiny', '0.039';
};