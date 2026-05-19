({
	init: function (component) {
		var flow = component.find("flowData");
		flow.startFlow("Account_FL002_Create_Account_Screen");

		var maximizeButton = document.querySelector('[title="Maximize"]');

        if (maximizeButton) {
            maximizeButton.click();
        }
	},

	handleStatusChange: function (component, event) { 
		if (event.getParam('status') === "FINISHED") {
			$A.get("e.force:closeQuickAction").fire();
		}
	}

})