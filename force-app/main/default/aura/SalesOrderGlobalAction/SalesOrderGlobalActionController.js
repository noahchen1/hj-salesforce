({
  init: function (component) {
    var maximizeButton = document.querySelector('[title="Maximize"]');
    var modalContainer = document.querySelector(".slds-modal__container");

    if (maximizeButton) {
      maximizeButton.click();
    }

    if (modalContainer) {
      modalContainer.style.width = "80%";
      modalContainer.style.maxWidth = "80%";
    }
  }
});
