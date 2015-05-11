If you want your local config to use the filesystem, use a different app name,
or use a different login, create a `deploy/local.properties` file.

For example:

    user=admin
    password=secret
    app-modules-db=filesystem
    modules-db=filesystem
    test-modules-db=filesystem
    modules-root=/filesystem/path/to/svn-vista-analytics/application/src

# Deployment instructions
- ./ml local setup_credentials
- ./ml local setup_tls
- ./ml local bootstrap
- ./ml local configure_alerting
- ./ml local setup_sites
- ./ml local deploy modules

# Clearing all ontology data
- ./ml local clean_ontology

# Loading icd9 data
- ./ml local load_icd9
- ./ml local clean_icd9

# Loading or clearing RXNORM data
- ./ml local load_rxnorm
- ./ml local clean_rxnorm

# Enrich RXNORM data with DEA data
- ./ml local load_dea
- ./ml local clean_dea

# Loading or clearing test data
- ./ml local load_testdata
- ./ml local clean_testdata
- To remove PTF records only: ./ml local clean_site_ptf TEST
- To remove C&P records only: ./ml local clean_site_cp TEST

# Loading site data
- make sure the VPR data is available at /home/data/sites/SITENAME/vpr
- make sure the PTF data is available at /home/data/sites/SITENAME/ptf
- make sure the CP data is available at /home/data/sites/SITENAME/cp
- ./ml local load_site SITENAME
- To load PTF only: ./ml local load_site_ptf /path/to/data
- To load C&P only: ./ml local load_site_cp /path/to/data

# Clearing site data
- ./ml local clean_site SITENAME
- To remove PTF records only: ./ml local clean_site_ptf SITENAME
- To remove C&P records only: ./ml local clean_site_cp SITENAME

# Enriching data
- Unenriched data is automatically enriched via the load_site and load_testdata targets.
- To manually (re)enrich all data, use one of the following commands:
- ./ml local enrich_unenriched_data
- ./ml local enrich_all_data

For other environments, substitue `dev` or `uat` or `prod` for `local`.
When setting up some environments you may need to add an extra line
to the properties file before configuring TLS, for example
`uat-server=localhost`.

# User management

Create a new user:

    ./ml local create_user vista1

Delete a user:

    ./ml local delete_user vista1

List application users, including the default user:

    ./ml local list_users

# Site management

To mark sites mature or immature, or to add geolocations for site facilities:

- Edit deploy/sites.xml
- ./ml local setup_sites

# For SSL/TLS operation

After `setup_credentials` and before `bootstrap`, run `./ml local setup_tls`.

If you need to recreate the certificate, follow these steps:
- ./ml local clean_tls
- ./ml local setup_tls
- ./ml local bootstrap

Note that `clean_tls` will throw `PKI-TMPLINUSE` if any appserver is
using the certificate template. So you may need to temporarily disable
TLS/SSL on the appserver.

To do this, or to run a local environment without TLS/SSL, add this
property to your `deploy/{$ENVIRONMENT}.properties` file:

    ssl-certificate-template=

In this case you can skip the `setup_tls` operation.