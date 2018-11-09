# URI Service (Application)

**URI Service** is a standalone Rails 5 application that creates/stores local and temporary terms and caches external URI terms. To start the application's only interface will be a JSON api, though we see expanding the application to include html pages for local terms.

URI Service makes some assumptions about how URIs should be organized. A URI is always related to a vocabulary. A vocabulary has many URI terms. Multiple authorities might be represented within a vocabulary. A URI must be unique to a vocabulary, but a URI can appear in multiple vocabularies.

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
      { "string_key": "collections" , "label": "Collections" },
      { "string_key": "name" , "label": "Names" }
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
     "label": "Names"
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
      "label": "Names"
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
     "label": "Names"
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
  ```

  Allowed query fields:
    - `q`: query term labels using fuzzy matching
    - `authority`: facet by authority
    - `uri`: search by exact uri string
    - `label`: search by exact label string

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
        "pref_label": 'Carla Galarza',
        "uri":"https://id.library.columbia.edu/term/1111-2222-3333-...",
        "authority": "local",
        "custom_field_1": "something"
      },
      {
        "pref_label": 'Eric O'Hanlon',
        "uri":"https://id.library.columbia.edu/term/4444-5555-6666...",
        "authority": "local",
        "custom_field_2": "another thing"
      }
    ]
  }
  ```

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
        "alt_label": {
          "type": "array",
  	  "items": { "type": "string" },
  	  "title": "Alternate Label",
        },
        "custom_field_1": {
          "type": "string",
          "title" "Custom Field 1"
        },
        "custom_field_2": {
          "type": "number",
          "title": "Custom Field 2"
        }
      }
    }
  }
  ```
