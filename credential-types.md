## CredHub Credential Types

CredHub has introduced credential types to make generation and management of multi-part credentials easier. For example, a TLS certificate contains 3 parts - root CA, certificate and private key. If these were stored as separate objects, the association between them may not be clear.

Credentials have a maximum size of 64 KB.

CredHub supports the following credential types: 

* **Value** - This type holds a single string value. It is meant for arbitrary configurations and other non-generated or validated strings. 

  ```json
  {
    "name": "/example/value",
    "type": "value",
    "value": "/var/vcap/jobs/credhub/example.sh",
    "version_created_at": "2016-10-13T20:59:28Z"
  }
  ```

* **JSON** - This type holds an arbitrary json object. It is meant for static configurations with many values where it is not efficient to separate out specific values into typed credentials. 

  ```json
  {
    "name": "/example/value",
    "type": "json",
    "value": {
      "key": 123,
      "key_list": [ "val1", "val2", "val3" ],
      "is_true": true
    },
    "version_created_at": "2016-10-13T20:59:28Z"
  }
  ```

* **Password** - This type holds a single string value. It is meant for passwords and other random string credentials. Values for this type may be automatically generated. 

  ```json
  {
    "name": "/example/password",
    "type": "password",
    "value": "nZaowPHTl0CQYVyYA0nV7ayHVulCBU3WTmwJKiZm",
    "version_created_at": "2016-10-13T21:03:42Z"
  }
  ```

* **User** - This type holds username and password values. The response also includes a derived SHA-512 hash of the password. It is meant for username and passwords combination credentials and passwords which require a hashed password value. Values for this type may be automatically generated. 

  ```json
  {
    "name": "/example/user",
    "type": "user",
    "value": {
      "username": "zCpbxxHMNmLvwjvAUhHT",
      "password": "nZaowPHTl0CQYVyYA0nV7ayHVulCBU3WTmwJKiZm",
      "password_hash": "$6$oCjU9.sR$Eeeu5sZP636cVNbpZLaeVbHlsr.zrs6/ygOkiBlGEEBq4zh3j3ybGHAp/EKvxhQ8NDQPqlYyqDK9X36XNJHru1"
    },
    "version_created_at": "2016-10-13T21:03:42Z"
  }
  ```

* **Certificate** - This type holds an object containing a root CA, certificate and private key. It it meant for key pair applications, such as TLS connections, that utilize a certificate. Values for this type may be automatically generated. 

  ```json
  {
    "name": "/example/certificate",
    "type": "certificate",
    "value": {
      "ca": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----",
      "certificate": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"
    },
    "version_created_at": "2016-10-13T21:07:37Z"
  }
  ```

* **SSH** - This type holds an object containing an SSH-formatted public key and private key. It is meant for key pairs used to establish SSH connections. Values for this type may be automatically generated. 

  ```json
  {
    "name": "/example/ssh",
    "type": "ssh",
    "value": {
      "public_key": "ssh-rsa AAA...PLx user@location",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"
    },
    "version_created_at": "2016-10-13T21:10:44Z"
  }
  ```

* **RSA** - This type holds an object containing an RSA public key and private key. It is meant for RSA key pairs (without certificate). Values for this type may be automatically generated. 

  ```json
  {
    "name": "/example/rsa",
    "type": "rsa",
    "value": {
      "public_key": "-----BEGIN PUBLIC KEY-----...-----END PUBLIC KEY-----",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"
    },
    "version_created_at": "2016-10-13T21:13:41Z"
  }
  ```

## Consuming CredHub Types in Releases

The BOSH Director will interpolate the key "value" from the credential response for a deployment variable. For example, in a deployment containing the above password credential, BOSH will substitute `"nZaowPHTl0CQYVyYA0nV7ayHVulCBU3WTmwJKiZm"` for the variable. If the same is done with the above certificate credential, the below object will be substituted. 

```json
{
  "ca": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----",
  "certificate": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----",
  "private_key": "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----"
}
```

Translated to yaml:
```yaml
  ca: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE------
  certificate: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE------
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY------
```

If you want to leverage a non-string typed credentials, you must update your release to properly consume the new format. The following example shows how to configure a release to accept the above certificate credential. It includes an example to instruct users on how to define the values if they are not using a CredHub credential. 

**Release job spec:**

```yml
---
name: demo

properties:
  demo.tls:
    description: "Certificate and private key for TLS connection to API"
    example: |
        ca: |
          -----BEGIN CERTIFICATE-----
          ...
          -----END CERTIFICATE-----
        certificate: | 
          -----BEGIN CERTIFICATE-----
          ...
          -----END CERTIFICATE-----
        private_key: |
          -----BEGIN RSA PRIVATE KEY-----
          ...
          -----END EXAMPLE RSA PRIVATE KEY-----
  admin-password:
    description: "Admin password for the application"
    example: nZaowPHTl0CQYVyYA0nV7ayHVulCBU3WTmwJKiZm
```

**Job Template ERB:**

```erb
api-ca=<%= p("demo.tls.ca") %>
api-certificate=<%= p("demo.tls.certificate") %>
api-private-key=<%= p("demo.tls.private_key") %>
admin-password=<%= p("admin-password") %>
```

**Deployment manifest:**

CredHub and BOSH are integrated to provide the option of generating the required credential values on deployment. 
You can define these generation parameters in the deployment manifest under the `variables` section, as shown in the example below.

```yml
---
name: demo-deploy

variables:
- name: demo-ca
  type: certificate
  options:
    is_ca: true
    common_name: 'Demo Certificate Authority'
- name: demo-tls
  type: certificate
  options:
    ca: demo-ca
    common_name: example.com
    alternative_names:
    - example.com
    - www.example.com
    extended_key_usage:
    - client_auth
- name: admin-password
  type: password
  options:
    length: 40

instance_groups:
  properties:
    demo:
      tls: ((demo-tls))
      admin-password: ((demo-password))
```

Updating a release for other types is similar to the example above, being mindful of the key name for each value you wish to consume. 