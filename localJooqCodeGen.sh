#!/bin/bash -e -x

# *********************************************************** #

function fnClean() {
  rm -rf jOOQ-3.19.10
  rm -f jOOQ-3.19.10.zip

  rm -f postgresql-42.7.3.jar
  rm -rf mysql-connector-j-9.0.0
  rm -f mysql-connector-j-9.0.0.zip

  local declare schemaList=(testjooq)
  for schema in ${schemaList[@]}; do
    rm -f ${schema}.xml
    rm -rf entities${schema}
  done
}

function fnGetJooq() {
  rm -rf jOOQ-3.19.10
  rm -f jOOQ-3.19.10.zip
  curl -LOJ 'https://www.jooq.org/download/license-accepted?type=oss&file=jOOQ-3.19.10.zip'
  unzip jOOQ-3.19.10.zip
}

function fnGetJdbcDriver() {
  rm -f postgresql-42.7.3.jar
  curl -LOJ 'https://jdbc.postgresql.org/download/postgresql-42.7.3.jar'

  rm -rf mysql-connector-j-9.0.0
  rm -f mysql-connector-j-9.0.0.zip
  curl -LOJ 'https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-j-9.0.0.zip'
  unzip mysql-connector-j-9.0.0.zip
}

function fnCreateEntitySchemaConfig() {
  rm -f testjooq.xml
  echo "\
<configuration
  xmlns=\"http://www.jooq.org/xsd/jooq-codegen-3.19.8.xsd\">
  <jdbc>
    <driver>org.postgresql.Driver</driver>
    <url>jdbc:postgresql://localhost:5432/testdb</url>
    <user>testuser</user>
    <password>testpass</password>
  </jdbc>
  <generator>
    <name>org.jooq.codegen.JavaGenerator</name>
    <database>
      <name>org.jooq.meta.postgres.PostgresDatabase</name>
      <includes>.*</includes>
      <excludes></excludes>
      <inputSchema>jooqtest</inputSchema>
    </database>
    <generate>
      <fullyQualifiedTypes>java\.lang\.Object</fullyQualifiedTypes>
    </generate>
    <target>
      <packageName>com.testjooq</packageName>
      <directory>testjooq/src/main/java</directory>
    </target>
  </generator>
</configuration>" > testjooq.xml
}

function fnRunJooqCodeGen() {
  local declare schemaList=()
  case $1 in
    testjooq)
      schemaList+=($1)
      ;;
    *)
      schemaList+=(testjooq)
      ;;
  esac

  for schema in ${schemaList[@]}; do
    rm -rf ${schema}/src/main/java/com
    java -cp jOOQ-3.19.10/jOOQ-lib/r2dbc-spi-1.0.0.RELEASE.jar:jOOQ-3.19.10/jOOQ-lib/reactive-streams-1.0.3.jar:jOOQ-3.19.10/jOOQ-lib/jakarta.xml.bind-api-3.0.0.jar:jOOQ-3.19.10/jOOQ-lib/jooq-3.19.10.jar:jOOQ-3.19.10/jOOQ-lib/jooq-codegen-3.19.10.jar:jOOQ-3.19.10/jOOQ-lib/jooq-meta-3.19.10.jar:postgresql-42.7.3.jar:mysql-connector-j-9.0.0/mysql-connector-j-9.0.0.jar:. org.jooq.codegen.GenerationTool ${schema}.xml
  done
}

function fnBuildEntitySchema() {
  local declare schemaList=()
  case $1 in
    testjooq)
      schemaList+=($1)
      ;;
    *)
      schemaList+=(testjooq)
      ;;
  esac
  mvn clean package -DskipTests -pl ${schemaList[@]}
}

# *********************************************************** #

function main() {
  case $1 in

    getJooq)
      fnGetJooq
      ;;

    getJdbcDriver)
      fnGetJdbcDriver
      ;;

    createEntitySchemaConfig)
      fnCreateEntitySchemaConfig
      ;;

    runJooqCodeGen)
      fnRunJooqCodeGen ${entitySchema}
      ;;

    buildEntitySchema)
      fnBuildEntitySchema ${entitySchema}
      ;;

    clean)
      fnClean
      ;;

    all)
      fnClean
      fnGetJooq
      fnGetJdbcDriver
      fnCreateEntitySchemaConfig
      fnRunJooqCodeGen ${entitySchema}
      fnBuildEntitySchema ${entitySchema}
      ;;

    *)
      echo "unknown: $1"
      ;;

  esac
}

# *********************************************************** #
# commands details,
# getJooq - download jooq binary
# getJdbcDriver
# createEntitySchemaConfig
# runJooqCodeGen
# buildEntitySchema
# clean
# all
execCommand=all
entitySchema=all

# *********************************************************** #
# parse command line args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--command)
            execCommand="$2"
            shift
            ;;
        -s|--schema)
            entitySchema="$2"
            shift
            ;;
        *)
            echo "Error: Unknown parameter passed: $1"
            exit 1
            ;;
    esac
    shift
done
# *********************************************************** #

main ${execCommand}
