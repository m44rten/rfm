SaxChange::Template.document(YAML.load(<<-EEOOFF))

#!/usr/bin/env ruby
# This is a template for parsing 'databases' from FMPXMLRESULT fms response.
# This also works well for parsing 'layouts' command response.
# What about scripts?
---
# This is not functionaly required but helps with debugging
name: fmpxmlresult
initial_object: "Rfm::Resultset.new(**config)"
attach_elements: _meta
attach_attributes: _meta
create_accessors: all

elements:
# # Doctype callback is different for different backends.
# - name: doctype
#   attach: none
#   attributes:
#   - name: value
#     as_name: doctype
- name: fmpxmlresult
  attach: none
- name: product
- name: errorcode
  attach: none
  # I've disabled this for v4 dev.
  #before_close: :check_for_errors
  attributes:
  - name: text
    as_name: error
- name: database
#   attach: none
#   # Disabled for v4 dev.
#   #before_close: [object, end_datasource_element_callback, self]
#   attributes:
#   - name: total_count
#     accessor: none
- name:  metadata
  attach: none
- name: field
  # These two steps can be used to create the attachment to resultset-meta automatically,
  # but the field-mapping translation won't happen.
  # attach: [_meta, 'Rfm::Metadata::Field', allocate]
  # as_name: field_meta
  attach: [cursor, 'Rfm::Metadata::Field', ':allocate']
  delimiter: name
  attach_attributes: private
  before_close: [object, field_definition_element_close_callback, self]
- name: resultset
  attach: none
  attributes:
  - name: found
    as_name: count
# From here on, this is designed to return a simple array containing
# the single 'data' column from each row. This is intended for
# db names, layout names, and sript names only.
- name: row
  attach: none
  # This doesn't seem to work here.
  #attach_attributes: none
  attributes:
  - name: modid
    attach: none
  - name: recordid
    attach: none
- name: col
  attach: none
- name: data
  attach: none
  attributes:
  - name: text
    attach: values
    compact: true
    
EEOOFF



# This works but only returns minimal info.
#attach_elements: none
#attach_attributes: none
#compact: true 
# elements:
# - name: 'doctype'
#   attach: none
#   attributes:
#   - name: value
#     as_name: doctype
#     attach: private
#     accessor: all
# - name: resultset
#   attach: none
#   attributes:
#   - name: found
#     attach: private
# - name: data
#   attach: none
#   attributes:
#   - name: text
#     attach: values
#     compact: true

# elements:
# 
# - name: resultset
#   attach: none
#   create_accessors: all
#   attributes:
#   - name: found
#     create_accessors: all
#     attach: private
# - name: row
#   as_name: rows
#   compact: true
#   attach: array
#   attach_attributes: none
#   elements:
#   - name: col
#     as_name: columns
#     attach: array
#     compact: true


# # This gets pretty much the same as above.
# elements:
# 
# - name: data
#   attach: array
#   #compact: true
#   #attach_attributes: this-wont-work-if-model-is-attach:none
# 
#   attributes:
#   - name: text
#     as_name: database
#     attach: values
#     #compact: true


# # This doesn't work on its own.
# attributes:
# - name: text
#   attach: values
#   compact: true