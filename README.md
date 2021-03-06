Signet
======

_If you're havin' SSL problems, I feel bad for you, son. I got 99 problems, but
a cert ain't one._

[![Build Status](https://secure.travis-ci.org/SmartReceipt/signet.png)](https://travis-ci.org/SmartReceipt/signet)
[![Coverage Status](https://coveralls.io/repos/SmartReceipt/signet/badge.png?branch=master)](https://coveralls.io/r/SmartReceipt/signet)
[![Code Climate](https://codeclimate.com/github/SmartReceipt/signet.png)](https://codeclimate.com/github/SmartReceipt/signet)
[![Dependency Status](https://gemnasium.com/SmartReceipt/signet.png)](https://gemnasium.com/SmartReceipt/signet)

Architecture
------------

A server runs and responds to a certificate signing requests POST-ed over HTTP
with a certificate. To use it, you set up the server, then make requests with a
client CLI. Both require minimal configuration.

Interoperability with legacy infrastructure is achieved through the use of
shims. See the **Shims** section below for more information.

Operating
---------

### Server ###

On the server,

```sh
git clone https://github.com/SmartReceipt/signet
cd signet
bundle
```

* Create `config/production.yml` (see **Configuration File** below for help).
* Add your CA certificate and private key to ssl/production as
    * `ssl/production/ca_certificate.pem` and
    * `ssl/production/ca_private_key.pem`.

The HTTP server is implemented as a [Sinatra][] app, so you just
start it up like any Rack app.

```sh
RACK_ENV=production rackup # or thin or passenger or whatever
```

### Client ###

On the client,

```sh
git clone https://github.com/SmartReceipt/signet
cd signet
bundle
```

Create `config/production.yml` (see **Configuration File** below for help).

```sh
RACK_ENV=production bin/signet-client
```

Now you have a signed certificate at `ssl/production/signed_certificate.pem`.

Configuration File
------------------

Set the configuration file to match your environment. See `config/test.yml` for
an example. Here's a rundown of all of the options.

### database ###

This section is used by [ActiveRecord][], so refer to ActiveRecord's
documentation for help. If you've configured a Rails app's database connection,
you know what to do.

### certificate_authority ###

This is the **certificate authority** configuration. This configures the
certificate authority operated by this application.

#### passphrase ####

The passphrase to unlock the private key.

#### subject ####

The components of the subject are used to construct the subject line of the
certificate authority. This must match your CA certificate. The order matters!

#### expiry_seconds ####

The amount of time in seconds that newly-created certificates will be valid.
`4.0e+8` is about 9.5 years, which is a nice number.

#### serial ####

The serial number of the CA certificate (only used when creating a certificate).
This should probably be `1`.

#### version ####

The X.509 version used to create new certificates. This number is zero-indexed,
so `2` is `3`--the latest version.

### client ###

The configuration for the client which can be run to obtain certficates from the
server.

#### identity_key ####

The `identity key` of the user requesting the certificate--checked against the
users table in the database.

#### server ####

The server URL. This should be set up on the clients to match the location of
the server that you set up.

#### name ####

The name (aka common name, aka CN) of the client requesting the certificate.
This should be fairly unique to the client. For most clients, you'll want to
base this on the host name or MAC address or some other distinguishing feature.


Development
-----------

### Authentication ###

All requests are authenticated before they're processed. For compatibility with
legacy requests, we have the ability to exempt certain routes from requiring
authentication.

#### Authentication Exemptions ####

Routes added to the exemptions list should be as specifically defined as
possible, e.g. not `/csr_gen/` but `/^\/csr_gen\/.*.pem$/`. To add a route to
the exemptions list, define it then add it, e.g.

```ruby
get '/csr_gen/:mac.pem' do |mac|
  # ...do stuff...
end
authentication_exemptions << /^\/csr_gen\/.*.pem$/
```

### Testing ###

Unit and integration testing is done with [RSpec][] and tasks are managed with
[Rake][].

```sh
git clone https://github.com/SmartReceipt/signet
cd signet
bundle
RACK_ENV=test rake init
rake
```

### Shims ###

For compatibility with legacy certificate signer requests, some shims are
required. These shims are located in the `lib/shims` directory and are
enumerated and described here.

#### Legacy Certificate Signer ####

This shim supports legacy certificate requests which are made in two parts. For
a complete description of how this works, see the comments in
`lib/signet/shims/legacy_certificate_signer.rb`.

API
---

### POST /csr ###

The API supports a single request: a POST to `/csr`.

#### Request ####

The request is a POST to `/csr` including as parameters:

* `csr`: a string containing a CSR in PEM format
* `auth`: a string matching an `identity_key` value in the `users` table of the
  database.

#### Response ####

| Result                   | Status Code | Body                                                                       |
| ------------------------ | ----------- | -------------------------------------------------------------------------- |
| Success                  | 200         | The generated certificate in PEM format (encoded certificate only)         |
| Missing parameter        | 400         | A notification describing the parameter that is missing                    |
| Malformed CSR            | 400         | A notification that the CSR is missing or malformed                        |
| Bad `auth` value         | 403         | A notification that the `auth` value is invalid                            |
| Server Error             | 500         | A simple error message (normally caused by database connectivity problems) |

### Legacy Requests

Legacy requests are accomplished in two steps: a POST to `/csr/signme` and a GET
to `csr_gen/#{unique_id}.pem`.

### POST /csr/signme ###

#### Request ####

The request is a POST to `/csr` including as parameters:

* `csr`: an uploaded file *(not a string!)* containing a CSR in PEM format
* `identity_key`: a string matching an `identity_key` value in the `users` table
  of the database.

#### Response ####

| Result                   | Status Code | Body                                                                                                      |
| ------------------------ | ----------- | --------------------------------------------------------------------------------------------------------- |
| Success                  | 200         | No body is returned.                                                                                      |
| Missing parameter        | 400         | A notification describing the parameter that is missing                                                   |
| Malformed CSR            | 400         | A notification that the CSR is missing or malformed                                                       |
| Bad `identity_key` value | 403         | A notification that the `identity_key` value is invalid                                                   |
| Server Error             | 500         | A simple error message (normally caused by database connectivity problems)                                |

### GET /csr_gen/#{unique_id}.pem ###

#### Request ####

The request is a GET to `/csr_gen/#{unique_id}.pem` where `#{unique_id}` is the `CN`
from the `/csr/signme` CSR.

#### Response ####

The response is the certificate

| Result                   | Status Code | Body                                                                                                      |
| ------------------------ | ----------- | --------------------------------------------------------------------------------------------------------- |
| Success                  | 200         | The generated certificate in PEM format (encoded certificate AND the plain text certificate concatenated) |
| Certificate not found    | 404         | No body is returned if the certificate does not exist in the cache.                                       |

Contributing
------------

Bugs? Features? Comments? File an issue or a pull request. Thanks!

Author
------

[Justin Force][]

License
-------

[MIT License][]

[ActiveRecord]:http://api.rubyonrails.org/classes/ActiveRecord/Base.html
[Justin Force]:https://github.com/justinforce
[MIT License]:http://opensource.org/licenses/MIT
[RSpec]:https://github.com/rspec/rspec
[Rake]:https://github.com/jimweirich/rake
[Sinatra]:https://github.com/sinatra/sinatra
