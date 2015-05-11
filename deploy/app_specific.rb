#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the stuff in deploy/lib/server_config.rb
#
class ServerConfig
  def create_triggers()
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace trgr="http://marklogic.com/xdmp/triggers"
         at "/MarkLogic/triggers.xqy";

      trgr:create-trigger("ontology ingest", "Ontology ingest trigger",
        trgr:trigger-data-event(
            trgr:directory-scope("/ontology/", "1"),
            trgr:document-content("create"),
            trgr:post-commit()),
        trgr:trigger-module(
          # TODO triggers will not work for filesystem deployments
          xdmp:database("#{@properties['ml.modules-db']}"),
          "#{@properties['ml.modules-root']}",
          "/ingestion/ontology-trigger.xqy"),
        fn:true(), xdmp:default-permissions() )
    },
    { :db_name => @properties["ml.triggers-db"] }
  end

  def remove_triggers()
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace trgr="http://marklogic.com/xdmp/triggers"
         at "/MarkLogic/triggers.xqy";

      trgr:remove-trigger("ontology ingest")
    },
    { :db_name => @properties["ml.triggers-db"] }
  end

  def configure_alerting()
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
      try {
        let $uri := "/config/savedsearch-alert-config.xml"
        return if (alert:config-get($uri)) then alert:remove-triggers($uri)
        else
          let $config := alert:make-config(
            $uri,
            "VistA Analytics",
            "Alerting config for VistA saved searches",
            <alert:options/> )
          return
            alert:config-insert($config)
      } catch ($ex) {
        xdmp:log(('[configure_alerting]', $ex))
      };

      import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
      let $action := alert:make-action(
        "vista:savedsearch-match", 
        "Match on a user's saved search",
        xdmp:database("#{@properties['ml.modules-db']}"),
        "/", 
        "/alerts/savedsearch-match.xqy",
        <alert:options/>)
      return
        alert:action-insert("/config/savedsearch-alert-config.xml", $action);

      import module namespace alert = "http://marklogic.com/xdmp/alert" at "/MarkLogic/alert.xqy";
      import module namespace trgr="http://marklogic.com/xdmp/triggers" at "/MarkLogic/triggers.xqy";
      let $uri := "/config/savedsearch-alert-config.xml"
      let $trigger-ids :=
        alert:create-triggers(
          $uri,
          trgr:trigger-data-event(
            trgr:directory-scope("/vpr/", "infinity"),
            trgr:document-content(("create")),
            trgr:pre-commit()
          )
        )
      let $config := alert:config-get($uri)
      let $new-config := alert:config-set-trigger-ids($config, $trigger-ids)
      return alert:config-insert($new-config)
    },
    { :db_name => @properties["ml.content-db"]}
  end

  # It looks like we don't have access to src/lib here,
  # and we can't set the eval root.
  def clean_ontology()
    logger.info "cleaning ontology..."
    r = execute_query %Q{
      xquery version "1.0-ml";
      xdmp:directory-delete('/ontology/')
    },
    { :db_name => @properties["ml.content-db"] }
  end

  def clean_icd9()
    logger.info "cleaning icd9"
    estimate = -1
    while estimate != 0
      r = execute_query %Q{
      xquery version "1.0-ml";
      declare namespace va = "ns://va.gov/2012/ip401";
      declare namespace on = "ns://va.gov/2012/ip401/ontology";
      xdmp:estimate(
        (xdmp:directory('/ontology/ICD9/','infinity'))/on:concept)
          ,
         xdmp:node-delete(
          ((xdmp:directory('/ontology/ICD9/','infinity')/on:concept))[1 to 300])
      },
      { :db_name => @properties["ml.content-db"] }
      # as integer
      estimate = r.body.to_i
    end
  end

  def load_icd9()
    logger.info "loading icd9..."
    ARGV.push "-Xincgc"
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "src/ingestion/icd9.properties"
    ARGV.push "data/ontology/ICD9-csv.zip"
    recordloader
  end

  def clean_site_ptf()
    # args: sitename
    sitename = ARGV.shift
    if !sitename or sitename.length < 1
      logger.info "missing required argument: sitename"
      return
    end
    estimate = -1
    while estimate != 0
      logger.info "cleaning PTF data from site #{sitename}..."
      r = execute_query %Q{
        xquery version "1.0-ml";
        declare namespace va = "ns://va.gov/2012/ip401";
        xdmp:estimate(
          xdmp:directory('/vpr/#{sitename}/', 'infinity')/
            va:vpr/va:results/va:patientTreatments),
        xdmp:node-delete(
          (xdmp:directory('/vpr/#{sitename}/', 'infinity')/
             va:vpr/va:results/va:patientTreatments)[1 to 300])
      },
      { :db_name => @properties["ml.content-db"] }
      # as integer
      estimate = r.body.to_i
    end
  end

   def clean_site_race()
      # args: sitename
      sitename = ARGV.shift
      if !sitename or sitename.length < 1
        logger.info "missing required argument: sitename"
        return
      end
      estimate = -1
      while estimate != 0
        logger.info "cleaning race data from site #{sitename}..."
        r = execute_query %Q{
          xquery version "1.0-ml";
          declare namespace va = "ns://va.gov/2012/ip401";
          xdmp:estimate(
            xdmp:directory('/vpr/#{sitename}/', 'infinity')/
              va:vpr/va:results/va:demographics/va:patient/va:races),
          xdmp:node-delete(
            (xdmp:directory('/vpr/#{sitename}/', 'infinity')/
               va:vpr/va:results/va:demographics/va:patient/va:races)[1 to 500])
        },
        { :db_name => @properties["ml.content-db"] }
        # as integer
        estimate = r.body.to_i
      end
    end

  def clean_dea()
    logger.info "cleaning dea..."
    r = execute_query %Q{
      xquery version "1.0-ml";
      declare namespace dea="ns://va.gov/2012/ip401/ontology/dea" ;
      declare namespace rx="ns://va.gov/2012/ip401/ontology/rxnorm" ;
      xdmp:directory('/ontology/rxnorm/', 'infinity')/rx:concept[
        @dea-schedule or @dea-id ]
      ! (xdmp:node-delete(@dea-id), xdmp:node-delete(@dea-schedule))
    },
    { :db_name => @properties["ml.content-db"] }
  end

  def load_dea()
    logger.info "loading dea..."
    ARGV.push "-Xincgc"
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "src/ingestion/dea.properties"
    ARGV.push "data/rxnorm/dea.zip"
    recordloader
  end

  def clean_rxnorm()
    logger.info "cleaning rxnorm..."
    r = execute_query %Q{
      xquery version "1.0-ml";
      xdmp:directory-delete('/ontology/rxnorm/')
    },
    { :db_name => @properties["ml.content-db"] }
  end

  def load_rxnorm()
    logger.info "loading rxnorm..."
    ARGV.push "-Xincgc"
    # currently not enough disk space on INTG to support RxNorm
    if @environment != "dev"
      return
    end
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "src/ingestion/rxnorm.properties"
    ARGV.push "data/rxnorm/rxnorm.zip"
    recordloader
  end

  def clean_site_cp()
    # args: sitename
    sitename = ARGV.shift
    if !sitename or sitename.length < 1
      logger.info "missing required argument: sitename"
      return
    end
    estimate = -1
    while estimate != 0
      logger.info "cleaning CP data from site #{sitename}..."
      r = execute_query %Q{
        xquery version "1.0-ml";
        declare namespace va = "ns://va.gov/2012/ip401";
        xdmp:estimate(
          xdmp:directory('/vpr/#{sitename}/', 'infinity')/
            va:vpr/va:results/va:cpRecords),
        xdmp:node-delete(
          (xdmp:directory('/vpr/#{sitename}/', 'infinity')/
             va:vpr/va:results/va:cpRecords)[1 to 500])
      },
      { :db_name => @properties["ml.content-db"] }
      # as integer
      estimate = r.body.to_i
    end
  end

  def clean_site()
    # args: sitename
    sitename = ARGV.shift
    if !sitename or sitename.length < 1
      logger.info "missing required argument: sitename"
      return
    end
    logger.info "cleaning site #{sitename}..."
    r = execute_query %Q{
      xquery version "1.0-ml";
      xdmp:directory-delete('/vpr/#{sitename}/')
    },
    { :db_name => @properties["ml.content-db"] }
  end

  def clean_testdata()
    ARGV.push "TEST"
    clean_site
  end

  def load_site_vpr()
    # args: sitename path
    sitename = ARGV.shift
    if !sitename or sitename.length < 1
      logger.info "missing required argument: sitename"
      return
    end

    path = ARGV.shift
    if !path or path.length < 1
      logger.info "missing required argument: path"
      return
    end

    if !File.exists?(path)
      logger.info "no such file or directory: #{path}"
      return
    end

    logger.info "loading VPR data from #{path}"
    ARGV.push "-Xincgc"
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "-DURI_PREFIX=#{sitename}"
    ARGV.push "src/ingestion/vpr.properties"
    ARGV.push path
    recordloader
  end

  def load_site_race()
    # args: sitename path
    sitename = ARGV.shift
    if !sitename or sitename.length < 1
      logger.info "missing required argument: sitename"
      return
    end
    path = ARGV.shift
    if !path or path.length < 1
      logger.info "missing required argument: path"
      return
    end
    if !File.exists?(path)
      logger.info "no such file or directory: #{path}"
      return
    end
    logger.info "loading VPR data from #{path}"
    ARGV.push "-Xincgc"
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "-DURI_PREFIX=#{sitename}"
    ARGV.push "src/ingestion/race.properties"
    ARGV.push path
    recordloader
  end


  def load_site_ptf()
    # args: path
    path = ARGV.shift
    if !path or path.length < 1
      logger.info "missing required argument: path"
      return
    end
    if !File.exists?(path)
      logger.info "no such file or directory: #{path}"
      return
    end
    logger.info "loading PTF data from #{path}"
    ARGV.push "-Xincgc"
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "src/ingestion/ptf.properties"
    ARGV.push path
    recordloader
  end


  def load_site_cp()
    # args: path
    path = ARGV.shift
    if !path or path.length < 1
      logger.info "missing required argument: path"
      return
    end
    if !File.exists?(path)
      logger.info "no such file or directory: #{path}"
      return
    end
    logger.info "loading CP data from #{path}"
    ARGV.push "-Xincgc"
    if @environment == "local"
      # use default heap size
    else
      # use larger heap size
      ARGV.push "-Xmx4096m"
    end
    ARGV.push "src/ingestion/cp.properties"
    ARGV.push path
    recordloader
  end

  def load_site()
    # args: sitename
    sitename = ARGV.shift
    if !sitename or sitename.length < 1
      logger.info "missing required argument: sitename"
      return
    end


    # preflight check directory locations
    site_path = ARGV.shift
    puts site_path

    if site_path.nil?
        puts "site_path is nil"
        site_path = "/home/data/sites/#{sitename}"

    end

    if !File.directory?(site_path)
      logger.info "no such directory: #{site_path}"
      return
    end

    # VPR
    ARGV.push sitename
    ARGV.push "#{site_path}/vpr"
    load_site_vpr
    # PTF
    ARGV.push "#{site_path}/ptf"
    load_site_ptf
    # CP
    ARGV.push "#{site_path}/cp"
    load_site_cp

    ARGV.push sitename
    ARGV.push "#{site_path}/race"
    load_site_race
    #enrich_unenriched_data

  end

  def load_testdata()
    logger.info "loading test data..."

    setup_sites

    ARGV.push "TEST"
    ARGV.push "data/test_data.zip"
    ARGV.push "-DTHREADS=1"
    #ARGV.push "-DFATAL_ERRORS=false"
    load_site_vpr

    ARGV.push "TEST"
    ARGV.push "data/raceExtract.zip"
    ARGV.push "-DTHREADS=1"
    load_site_race

    ARGV.push "data/newPtf.zip"
    ARGV.push "-DTHREADS=1"
    #ARGV.push "-DFATAL_ERRORS=false"
    load_site_ptf

    ARGV.push "data/cAndPSample.zip"
    ARGV.push "-DTHREADS=1"
    #ARGV.push "-DFATAL_ERRORS=false"
    load_site_cp
    #enrich_unenriched_data
  end

  def enrich_patients_drugs_list()
      ARGV.push "--uris=/corb/get-non-patient-drug-list-uris.xqy"
      ARGV.push "--modules=/corb/enrich-patient-drug-list.xqy"
      ARGV.push "--threads=8"
      corb
  end

  def enrich_patients_diagnoses_list()
      ARGV.push "--uris=/corb/get-non-patient-diagnoses-list-uris.xqy"
      ARGV.push "--modules=/corb/enrich-patient-diagnoses-list.xqy"
      ARGV.push "--threads=8"
      corb
  end

  def enrich_exposures()
      ARGV.push "--uris=/corb/get-non-exposure-enriched-uris.xqy"
      ARGV.push "--modules=/corb/enrich-exposures.xqy"
      ARGV.push "--threads=8"
      corb
  end

  def events_data_fix()
      ARGV.push "--uris=/corb/get-all-record-uris.xqy"
      ARGV.push "--modules=/corb/events-data-fix.xqy"
      ARGV.push "--threads=8"
      corb
  end

  def enrich_concepts_data()
    ARGV.push "--uris=/corb/get-non-concepts-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-concepts.xqy"
    ARGV.push "--threads=8"
    corb
  end

  def enrich_unenriched_data()
    logger.info "enriching unenriched records..."

    enrich_concepts_data()

    ARGV.push "--uris=/corb/get-non-concepts-text-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-concepts-text.xqy"
    ARGV.push "--threads=8"
    corb

    #concepts enrichement should be called before geocode enrichment
    geocode_unenriched_data()

    ARGV.push "--uris=/corb/get-non-diagnosis-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-diagnoses.xqy"
    ARGV.push "--threads=8"
    corb
    ARGV.push "--uris=/corb/get-non-race-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-race.xqy"
    ARGV.push "--threads=8"
    corb
    ARGV.push "--uris=/corb/get-non-visit-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-visits.xqy"
    ARGV.push "--threads=8"
    corb
    ARGV.push "--uris=/corb/get-non-procedure-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-procedures.xqy"
    ARGV.push "--threads=8"
    corb

    enrich_drug_data

    enrich_patient_indicators_data

    ARGV.push "--uris=/corb/get-non-rx-enriched-uris.xqy"
    ARGV.push "--modules=/corb/enrich-rx.xqy"
    ARGV.push "--threads=8"
    corb

    if @environment != "local"
       enrich_nlp_data()
    end

  end

  def enrich_patient_indicators_data()
      ARGV.push "--uris=/corb/get-non-patient-indicators-enriched-uris.xqy"
      ARGV.push "--modules=/corb/enrich-patient-indicators.xqy"
      ARGV.push "--threads=8"
      corb
  end

  def enrich_patient_indicators_data_all()
      ARGV.push "--uris=/corb/get-all-record-uris.xqy"
      ARGV.push "--modules=/corb/enrich-patient-indicators.xqy"
      ARGV.push "--threads=8"
      corb
  end

  def enrich_drug_data()
     ARGV.push "--uris=/corb/get-non-text-enriched-uris.xqy"
     ARGV.push "--modules=/corb/enrich-text.xqy"
     ARGV.push "--threads=8"
     corb
  end

  def enrich_drug_data_all()
     ARGV.push "--uris=/corb/get-all-record-uris.xqy"
     ARGV.push "--modules=/corb/enrich-text.xqy"
     ARGV.push "--threads=8"
     corb
  end

  def enrich_nlp_data()
     ARGV.push "--uris=/corb/get-non-nlp-enriched-uris.xqy"
     ARGV.push "--modules=/corb/enrich-notes-nlp.xqy"
     ARGV.push "--threads=5"
     corb
  end

  def enrich_nlp_data_all()
     ARGV.push "--uris=/corb/get-all-record-uris.xqy"
     ARGV.push "--modules=/corb/enrich-notes-nlp.xqy"
     ARGV.push "--threads=5"
     corb
  end

  def enrich_concepts_data_all()
      ARGV.push "--uris=/corb/get-all-record-uris.xqy"
      ARGV.push "--modules=/corb/enrich-concepts.xqy"
      ARGV.push "--threads=8"
      corb

  end

  def enrich_all_data()
    logger.info "enriching all records..."

    enrich_concepts_data_all()

    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-concepts-text.xqy"
    ARGV.push "--threads=8"
    corb

    #concepts enrichement should be called before geocode enrichment
    geocode_all_data()

    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-diagnoses.xqy"
    ARGV.push "--threads=8"
    corb
    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-race.xqy"
    ARGV.push "--threads=8"
    corb
    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-visits.xqy"
    ARGV.push "--threads=8"
    corb
    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-procedures.xqy"
    ARGV.push "--threads=8"
    corb

    enrich_drug_data_all

    enrich_patient_indicators_data_all

    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-rx.xqy"
    ARGV.push "--threads=8"
    corb

    if @environment != "local"
        enrich_nlp_data_all()
    end
  end

  def geocode_unenriched_data()

     logger.info "geocoding unenriched data..."
     ARGV.push "--uris=/corb/get-non-facility-address-enriched-uris.xqy"
     ARGV.push "--modules=/corb/enrich-facility-addresses.xqy"
     ARGV.push "--threads=8"
     corb

     ARGV.push "--uris=/corb/get-non-patient-address-enriched-uris.xqy"
     ARGV.push "--modules=/corb/enrich-patient-addresses.xqy"
     ARGV.push "--threads=8"
     corb

     ARGV.push "--uris=/corb/get-non-text-geo-address-enriched-uris.xqy"
     ARGV.push "--modules=/corb/enrich-text-geo-addresses.xqy"
     ARGV.push "--threads=8"
     corb
  end

  def geocode_all_data()
    logger.info "geocoding all data..."

    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-facility-addresses.xqy"
    ARGV.push "--threads=8"
    corb

    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-patient-addresses.xqy"
    ARGV.push "--threads=8"
    corb

    ARGV.push "--uris=/corb/get-all-record-uris.xqy"
    ARGV.push "--modules=/corb/enrich-text-geo-addresses.xqy"
    ARGV.push "--threads=8"
    corb
  end

  def build_cvd_depression_data()
   logger.info "building CVD depression data directory.."

   ARGV.push "--uris=/corb/get-all-record-uris.xqy"
   ARGV.push "--modules=/corb/build-cvd-depression-directory.xqy"
   ARGV.push "--threads=8"
   corb
  end

  def setup_credentials()
    logger.info "setup_credentials #{@environment}"
    # ml will error on invalid environment
    # ask user for admin username and password
    puts "What is the admin username?"
    user = gets.chomp
    puts "What is the admin password?"
    # we don't want to install highline
    # we can't rely on STDIN.noecho with older ruby versions
    system "stty -echo"
    password = gets.chomp
    system "stty echo"

    # Create or update environment properties file
    filename = "#{@environment}.properties"
    properties = {}
    properties_file = File.expand_path("../#{filename}", __FILE__)
    begin
      properties = ServerConfig.load_properties(properties_file, "")
    rescue => err
      # TODO ignore file-not-found exceptions
      puts "Exception: #{err}"
    end
    properties["user"] = user
    properties["password"] = password
    # hack for environment-specific settings
    # update these as needed
    case @environment
    when "dev"
      properties["content-forests-per-host"] = 2
    when "prod"
      properties["content-forests-per-host"] = 4
    else
    end
    # save new properties
    open(properties_file, 'w') {
      |f|
      properties.each do |k,v|
        f.write "#{k}=#{v}\n"
      end
    }
    logger.info "wrote #{properties_file}"
  end

  # Copy the site data into the content database, as '/config/sites.xml'.
  def setup_sites()
    logger.info "setup_sites #{@environment}"
    path = "deploy/sites.xml"
    if !File.exists?(path)
      logger.info "no such file or directory: #{path}"
      return
    end
    xml = IO.read(path)
    r = execute_query %Q{
      xquery version "1.0-ml";
      xdmp:document-insert(
        '/config/sites.xml', #{xml},
        xdmp:permission("#{@properties["ml.app-logged-in-role"]}", 'read')) },
    { :db_name => @properties["ml.content-db"] }
    logger.info(r.body)
  end

  def clean_tls()
    logger.info "clean_tls #{@environment}"
    # This should do nothing if the template does not exist.
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace pki = "http://marklogic.com/xdmp/pki"
        at "/MarkLogic/pki.xqy";
      pki:get-template-by-name(
        "#{@properties['ml.ssl-certificate-template']}")/
        pki:template-id/pki:delete-template(.)
    },
    { :db_name => "Security" }
  end

  def clean_ssl()
    clean_tls()
  end

  def setup_tls()
    logger.info "setup_tls #{@environment} #{@properties['ml.ssl-certificate-template']}"

    if @properties['ml.ssl-certificate-template'].length < 1
      logger.info "ssl-certificate-template undefined in this environment!"
      return
    end

    # TODO replace with va.gov certificate?

    # Do we already have the certificate?
    r = execute_query %Q{
      xquery version "1.0-ml";
      (: Create a new certificate template, if needed. :)
      import module namespace pki = "http://marklogic.com/xdmp/pki"
        at "/MarkLogic/pki.xqy";
      pki:get-template-by-name(
        "#{@properties['ml.ssl-certificate-template']}")
    },
    { :db_name => "Security" }
    logger.debug(r.body.length)

    # This will throw PKI-DUPNAME if the name already exists.
    if (r.body.length < 16)
      r = execute_query %Q{
        xquery version "1.0-ml";
        (: Create a new certificate template, if needed. :)
        import module namespace pki = "http://marklogic.com/xdmp/pki"
          at "/MarkLogic/pki.xqy";
         pki:insert-template(
           pki:create-template(
             "#{@properties['ml.ssl-certificate-template']}",
             "Self-signed certificate",
             "rsa",
             <pki:key-options xmlns="ssl:options">
               <key-length>2048</key-length>
             </pki:key-options>,
             (: TODO use something like ip401.va.gov for commonName? :)
             <req xmlns="http://marklogic.com/xdmp/x509">
               <version>2</version>
               <subject>
                 <countryName>US</countryName>
                 <stateOrProvinceName>VA</stateOrProvinceName>
                 <localityName>Springfield</localityName>
                 <organizationName>Information Innovators Inc.</organizationName>
                 <organizationalUnitName>IP401</organizationalUnitName>
                 <commonName>{ xdmp:hostname() }</commonName>
                 <emailAddress>mroberts@iiinfo.com</emailAddress>
               </subject>
               <v3ext>
                 <basicConstraints critical="false">CA:TRUE</basicConstraints>
                 <keyUsage critical="false">Certificate Sign, CRL Sign</keyUsage>
                 <nsCertType critical="false">SSL Server</nsCertType>
               </v3ext>
             </req>))
      },
      { :db_name => "Security" }
    end

  end

  def setup_ssl()
    setup_tls()
  end

  def list_users()
    logger.info "listing application users..."
    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace sec="http://marklogic.com/xdmp/security" at
        "/MarkLogic/security.xqy";
      for $u as xs:string in collection(
        sec:users-collection())/sec:user/sec:user-name
      where sec:user-get-roles($u) = '#{@properties["ml.app-role"]}'
      return $u
    },
    { :db_name => "Security" }
    logger.info r.body
  end

  def delete_user()
    # args: username
    username = ARGV.shift
    if !username or username.length < 1
      logger.info "missing required argument: username"
      return
    end

    r = execute_query %Q{
      xquery version "1.0-ml";
      import module namespace sec="http://marklogic.com/xdmp/security" at
        "/MarkLogic/security.xqy";
      if (not(sec:user-exists('#{username}'))) then ()
      else sec:remove-user('#{username}')
    },
    { :db_name => "Security" }
  end

  def create_user()
    # args: username
    username = ARGV.shift
    if !username or username.length < 1
      logger.info "missing required argument: username"
      return
    end

    # prompt for password
    puts "Password for #{username}:"
    # we don't want to install highline
    # we can't rely on STDIN.noecho with older ruby versions
    system "stty -echo"
    password = gets.chomp
    system "stty echo"

    logger.info "Creating #{username}..."
    r = execute_query %Q{
      import module namespace sec="http://marklogic.com/xdmp/security" at
        "/MarkLogic/security.xqy";
      if (sec:user-exists('#{username}'))
      then sec:user-set-password(
        '#{username}',
        '#{password}')
      else sec:create-user(
        '#{username}',
        '#{@properties["ml.app-name"]} user #{username}',
        '#{password}',
        '#{@properties["ml.app-logged-in-role"]}',
        (), ())
    },
    { :db_name => "Security" }
  end

  # TODO This might be a useful task to have.
  # The idea is to run a single XQuery script to fix a known problem,
  # for example a misformatted element.
  def fixup()
    # args: script
    script = ARGV.shift
    if !script or script.length < 1
      logger.info "missing required argument: script"
      return
    end
    if !File.exists?("src/fixup/#{script}")
      logger.info "no such file or directory: #{script}"
      return
    end
    logger.info "invoking #{script} at #{@properties["ml.modules-root"]}"

    # TODO invoke directly, or use corb?
    # If using corb, where do we get the URI query?
    # Would be nice to skip this extra invoke layer...
    r = execute_query %Q{
      xdmp:invoke(
        'fixup/#{script}', (),
        <options xmlns="xdmp:eval">
          <modules>{
            "#{@properties["ml.modules-db"]}" ! (
              if (. eq 'filesystem') then 0 else xdmp:database(.)) }</modules>
          <root>#{@properties["ml.modules-root"]}</root></options>) },
    { :db_name => @properties["ml.content-db"] }
    logger.info(r.body)
  end

  def drugsHeartReport()
      logger.info "Running the drugs heart disease analysis report..."

      ARGV.push "--uris=/corb/get-all-record-uris.xqy"
      ARGV.push "--modules=/corb/drugsHeartDiseaseAnalysis.xqy"
      ARGV.push "--threads=8"
      corb
  end

end
