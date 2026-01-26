import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

ApplicationWindow {
    id: mainWindow
    width: 1080
    height: 500
    visible: true
    title: qsTr("Libro")

    // Application state machine
    // States: checking, activation, setup, blocked, login, main
    property string appState: "checking"

    // Track if grace period warning was shown this session
    property bool graceWarningShown: false

    // Grace Period Warning Dialog
    GracePeriodWarningDialog {
        id: gracePeriodDialog
        daysRemaining: appManager ? appManager.graceDaysRemaining : 0

        onContinueClicked: {
            graceWarningShown = true
            // Continue to login or setup
            if (appManager && !appManager.hasAdminSetup) {
                appState = "setup"
            } else {
                appState = "login"
            }
        }

        onRenewClicked: {
            Qt.openUrlExternally("https://google.com") //libro.yoursite.com/renew
        }
    }

    // Main content loader
    Loader {
        id: mainLoader
        anchors.fill: parent

        source: {
            switch (appState) {
                case "checking":
                    return "LicenseCheckingPage.qml"
                case "activation":
                    return "ActivationPage.qml"
                case "setup":
                    return "FirstTimeSetupPage.qml"
                case "blocked":
                    return "BlockedPage.qml"
                case "login":
                    return "Login.qml"
                default:
                    return "LicenseCheckingPage.qml"
            }
        }

        active: true
    }

    // Handle page signals
    Connections {
        target: mainLoader.item
        ignoreUnknownSignals: true

        // From ActivationPage
        function onActivationComplete() {
            appState = "setup"
        }

        // From FirstTimeSetupPage
        function onSetupComplete() {
            appState = "login"
        }

        // From BlockedPage
        function onRetryValidation() {
            appState = "checking"
            checkLicenseStatus()
        }

        function onRenewClicked() {
            Qt.openUrlExternally("https://libro.yoursite.com/renew")
        }
    }

    // Check license on startup
    Component.onCompleted: {
        checkLicenseStatus()
    }

    function checkLicenseStatus() {
        appState = "checking"

        if (!appManager) {
            console.error("AppManager not available - showing activation page")
            appState = "activation"
            return
        }

        // Trigger license validation
        appManager.validateLicense()
    }

    // Handle license validation results
    Connections {
        target: appManager

        function onLicenseStatusChanged() {
            handleLicenseState()
        }

        function onValidationCompleted() {
            handleLicenseState()
        }
    }

    function handleLicenseState() {
        // Don't interrupt if already past login
        if (appState === "main") {
            // But still show grace period warning if needed
            if (appManager.isGracePeriod && !graceWarningShown) {
                gracePeriodDialog.open()
            }
            return
        }

        var status = appManager.licenseStatus
        console.log("License status:", status)

        if (status === "not_activated") {
            appState = "activation"
        } else if (status === "blocked") {
            appState = "blocked"
        } else if (status === "grace_period") {
            // Show warning dialog first
            if (!graceWarningShown) {
                gracePeriodDialog.open()
                // Dialog will handle navigation after user acknowledges
            } else {
                // Already shown this session, proceed
                if (!appManager.hasAdminSetup) {
                    appState = "setup"
                } else {
                    appState = "login"
                }
            }
        } else if (appManager.isLicenseValid) {
            // Valid license (trial or active)
            if (!appManager.hasAdminSetup) {
                appState = "setup"
            } else {
                appState = "login"
            }
        }
    }
}
