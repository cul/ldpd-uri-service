# URI Service (Application)
[![Build Status](https://travis-ci.org/cul/ldpd-uri-service.svg?branch=master)](https://travis-ci.org/cul/ldpd-uri-service) [![Coverage Status](https://coveralls.io/repos/github/cul/ldpd-uri-service/badge.svg?branch=master)](https://coveralls.io/github/cul/ldpd-uri-service?branch=master)

**URI Service** is a standalone Rails 5 application that creates/stores local and temporary terms and caches external URI terms. To start the application's only interface will be a JSON api, though we see expanding the application to include html pages for local terms.

URI Service makes some assumptions about how URIs should be organized. A URI is always related to a vocabulary. A vocabulary has many URI terms. Multiple authorities might be represented within a vocabulary. A URI must be unique to a vocabulary, but a URI can appear in multiple vocabularies.

Vocabularies allow the addition of custom fields for all terms that are stored within its scope. Different vocabularies can define different custom fields.

In order to use the JSON api, URI Service requires token authentication. URI Service does not provide granular authorization. The application that uses the api should control authorization in any way it deems necessary.

## Definitions
#### External Term
Used when caching a value/URI pair from an external controlled vocabulary within URI Service. Example: We want to add an entry for U.S. President Abraham Lincoln to our URI Service datastore, so we'll create an external term that references his Library of Congress URI.

#### Local Term
Used when defining locally-managed terms in the URI Service. Automatically creates a local URI for a new local term. Example: We want to maintain a vocabulary for various departments within a university, and we want to create locally-managed URIs for these departments.

#### Temporary Term
Used when you want to add a value to your URI Service datastore, but have no authority information about the term or do not wish to create a local URI. No two temporary terms within the same vocabulary can have the same value. Basically, a temporary term is intended to identify an exact string value rather than identifying an intellectual entity. Temporary terms should eventually be replaced by external or local terms later on when more information is known about the entity to which you are referring . Example: We want to record information about the author of an old and mysterious letter by "John Smith." We don't know which "John Smith," this refers to, so we'll create (or re-use) a temporary URI that's associated with the value "John Smith."

#### Custom Fields
TODO

## Installation
TODO

## Configuration
Various configurations can be changed in `config/uri_service.yml`.

### API Keys
TODO

### Local URI HOST
TODO

### Commit After Save
Our Solr configuration automatically soft commits all changes after a second and commits all changes after 30 seconds. This keeps things running smoothly in production environments because it prevents frequent, unnecessary commits to Solr. In test environments waiting a second for a document to appear is not ideal. Because of this there's a `commit_after_save` flag that can be set to `true` and this would commit each change immediately to Solr. This flag should only be set to `true` in development and test environments. The default value is `false`.

## Services (job queues, cache servers, search engines, etc.)
URI Services stores local, temporary and external terms in a mysql database. Solr is used to index terms for fast lookup and searching. Redis/Resque will be used to run scheduled jobs.

## Deployment instructions
TODO

## API v1

### Vocabularies
#### List Vocabularies
- **Request**
  `GET /vocabularies`

- **Success Response**

  Sorts vocabularies alphabetically by label. Defaults to `page = 1` and `per_page = 20`.

  _Status:_ 200

  _Body:_

  ```json
  {
    "page": 1,
    "per_page": 10,
    "total_results": 2,
    "vocabularies": [
      {
        "string_key": "collections" ,
        "label": "Collections",
        "custom_fields": {}
      },
      {
        "string_key": "name" ,
        "label": "Names",
        "custom_fields": {
          "name_type": {
            "label": "Name Type",
            "data_type": "string"
          }
        }
      }
    ]
  }
  ```

#### Find Single Vocabulary
- **Request**

  `GET /vocabularies/:string_key`

- **Successful Response**

  _Status:_ 200

  _Body:_
  ```json
  {
     "string_key": "names",
     "label": "Names",
     "custom_fields": {}
  }
  ```

#### Create Vocabulary
- **Request**

  `POST /vocabularies`

  `string_key` and 'label' are required parameters.

- **Success Response**

  _Status:_ `201`

  _Body:_
    ```json
    {
      "string_key": "names",
      "label": "Names",
      "custom_fields": {}

    }
    ```

#### Update Vocabulary
- **Request**

  `PATCH /vocabularies/:string_key`

  Only a vocabulary's `label` can be updated, `string_key` cannot be changed.

- **Success Response**

  _Status:_ 200

  _Body:_
  ```json
  {
     "string_key": "names",
     "label": "Names",
     "custom_fields": {}
  }
  ```

#### Delete Vocabulary
- **Request**

  `DELETE /vocabularies/:string_key`

- **Success Response**

  _Status:_ 204

  _Body:_ nil

- **Error Response**
  - If resource does not exist returns `404`
  - If not successful return `500`


#### Send back description/instruction
- **Request**

  `OPTIONS /vocabularies/`
- **Success Response**
  TODO

### Vocabularies/Custom Fields
#### Add Custom Field to Vocabulary
- **Request**

  `POST /vocabularies/:string_key/custom_fields`

  _Required params:_ `field_key`, `label` and `data_type`

  _Supported data_type:_ `string`, `integer`, `boolean`

- **Success Response**

  _Status:_ 201

  _Body:_ NOT SURE

#### Update Custom Field
- **Request**

  `PATCH /vocabularies/:string_key/custom_fields/:field_key`

  _Optional params:_ `label`

  `field_key` and `data_type` cannot be changed after creation.

- **Success Response**

  _Status:_ 200

  _Body:_ NOT SURE

#### Delete Custom Field from Vocabulary
- **Request**

  `DELETE /vocabularies/:string_key/custom_fields/:field_key`

  Deletes custom field from vocabulary object, fields within terms will not be deleted, they will just be ignored.

- **Success Response**

  _Status:_ 200

  _Body:_ none


### Vocabularies/Terms

#### List/Search through Terms in Vocabulary
- **Request**

  `GET /vocabularies/:string_key/terms`

  Examples:
  ```
  GET /vocabularies/:string_key/terms?page=1&per_page=20`
  GET /vocabularies/:string_key/terms?q=smith&authority=naf&page=1&per_page=20`
  GET /vocabularies/:string_key/terms?uri=https://creativecommons.org/publicdomain/zero/1.0/
  GET /vocabularies/:string_key/terms?label=Smith # returns temp term b/c no uri was given
  GET /vocabularies/:string_key/terms?custom_field=123
  ```

  Allowed query fields:
    - `q`: query term labels using fuzzy matching
    - `authority`: search by exact authority string
    - `uri`: search by exact uri string
    - `pref_label`: search by exact pref_label string
    - `alt_labels`: search by exact alt_labels string
    - `term_type`: search by exact term_type
    - additionally you will be able to query by any custom field name defined in that vocabulary, for example, if a custom field name is `name_type`, doing the following search would search through the terms in that vocabulary for any terms that contain 'personal' in the name_type field. If a `name_type` field is not defined within that vocabulary you will get no results.
      `GET /vocabularies/:string_key/terms?name_type=personal`

  Other allowed params:
    - `per_page`: number of terms per page, default: 20
    - `page`: page to display

- **Success Response**

  Sorted primarily by match score (in the case of a q search), secondarily by label alphabetical sort

  _Status:_ 200

  _Body:_
  ```json
  {
    "page": 1,
    "per_page": 25,
    "total records": 55,
    "terms": [
      {
        "pref_label": "Carla Galarza",
        "uri":"https://id.library.columbia.edu/term/1111-2222-3333-...",
        "authority": "local",
        "custom_field_1": "something"
      },
      {
        "pref_label": "Eric O'Hanlon",
        "uri":"https://id.library.columbia.edu/term/4444-5555-6666...",
        "authority": "local",
        "custom_field_2": "another thing"
      }
    ]
  }
  ```

#### Find Single Term
- ** Request **

  ` GET /vocabularies/:string_key/terms/:uri`

- ** Success Response **

  _Status:_ 200

  _Body:_ json representation of object

#### Create term
- **Request**

  `POST /vocabularies/:string_key/terms`

  _Required params:_ term_type, label, uri (unless term_type = local or temporary)

  _Optional params:_ authority, and any vocabulary-specific custom fields

- **Success Response**

  _Status:_ 201

  _Body:_ json representation of object

#### Update Term
- **Request**

  `PATCH /vocabularies/:string_key/terms/:uri`

  URI should be URL-encoded

  Can only change label and custom fields. URI and term_type can only be added with a create.

- **Success Response**

  _Status:_ 200

  _Body:_ JSON representation of object

- **Error Response**
  - return 404 (if object cannot be found)

#### Delete term
- **Request**

  `DELETE  /vocabularies/:string_key/terms/:uri`

  URI should be URL-encoded.

  Deletes the term for that vocabulary only.
- **Success Response**

  _Status:_ 204

  _Body:_ none

- **Error Response**
  - 404 if object not found
  - 500 if error deleting object


#### Send back instructions
This endpoint will help define the terms returned and should help in the creating of forms.

- **Request**
  `OPTIONS /vocabularies/:string_key/terms`

- **Success Response**
  WORK IN PROGRESS

  _Status:_ 200

  _Body:_
  ```json
  {
    "POST": {
      "$schema": "http://json-schema.org/draft-07/schema#"
      "description": "Create a term in a vocabulary",
      "required" : ["pref_label"]
      "properties": {
        "pref_label": {
          "type": "string"
          "title": "Issue title."
        },
        "alt_labels": {
          "type": "array",
  	  "items": { "type": "string" },
  	  "title": "Alternate Label",
        },
        "custom_field_1": {
          "type": "string",
          "title" "Custom Field 1"
        },
        "custom_field_2": {
          "type": "integer",
          "title": "Custom Field 2"
        }
      }
    }
  }
  ```
