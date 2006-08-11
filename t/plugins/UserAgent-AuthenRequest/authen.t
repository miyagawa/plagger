use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== Without auth
--- input config
global:
  log:
    level: debug
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://irisresearch.library.cornell.edu/control/authBasic/authTest/
--- expected
like $warning, qr/401 Authorization Required/;

=== With auth
--- input config
global:
  log:
    level: debug
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://irisresearch.library.cornell.edu/control/authBasic/authTest/
  - module: UserAgent::AuthenRequest
    config:
      host: irisresearch.library.cornell.edu:80
      realm: "User: test Pass:"
      username: test
      password: this
--- expected
unlike $warning, qr/401 Authorization Required/;
like $warning, qr!200: http://irisresearch!;

=== With auth as list
--- input config
global:
  log:
    level: debug
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://irisresearch.library.cornell.edu/control/authBasic/authTest/
  - module: UserAgent::AuthenRequest
    config:
      credentials:
        - host: irisresearch.library.cornell.edu:80
          realm: "User: test Pass:"
          username: test
          password: this
--- expected
unlike $warning, qr/401 Authorization Required/;
like $warning, qr!200: http://irisresearch!;
