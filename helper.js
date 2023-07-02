/* eslint-disable no-unused-vars */
/* eslint-disable camelcase */
"use strict";

/**
 * Populate a select with options
 * @param {Object} select html select element
 * @param {Object} options object of key->value pairs
 * @param {string} def_value default value
 * @param {boolean} clear_first remove remove all existing values prior to populating
 */
function helper_populate_select(
  select,
  options,
  def_value = null,
  clear_first = true
) {
  if (clear_first) {
    // remove all options
    select.innerHTML = "";
  }
  // add options
  const keys = Object.keys(options);
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const value = options[key];
    const option = document.createElement("option");
    option.value = key;
    option.text = value;
    if (def_value && key === def_value) {
      option.selected = true;
    }
    select.appendChild(option);
  }
}

/**
 * Populate a select with options
 * @param {array} array  array/set
 * @return {Object} object of map of key -> value pairs with key=value
 */
function helper_array_to_object_of_key_eq_value(array) {
  return array.reduce((obj, value) => {
    obj[value] = value;
    return obj;
  }, {});
}
