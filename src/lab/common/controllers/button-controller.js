/*global define $ */

define(function () {

  return function ButtonController(component, scriptingAPI) {
    var $button,
        controller;

    $button = $('<button>').attr('id', component.id).html(component.text);
    $button.addClass("component");

    $button.click(scriptingAPI.makeFunctionInScriptContext(component.action));

    // Public API.
    controller = {
      // No modelLoadeCallback is defined. In case of need:
      // modelLoadedCallback: function () {
      //   (...)
      // },

      // Returns view container.
      getViewContainer: function () {
        return $button;
      },

      // Returns serialized component definition.
      serialize: function () {
        // Return the initial component definition.
        // Button doesn't have any state, which can be changed.
        return component;
      }
    };
    // Return Public API object.
    return controller;
  };
});
