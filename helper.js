// select: html element
// options: map of key -> value pairs
// def_value: default option
// clear_first: clear prior to populating
function helper_populate_select(select, options, def_value = null, clear_first = true) {
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
