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

    // Offline grace is silent (no dialog) - paying users keep working
    // undisturbed. This dialog is only shown once the grace window is exhausted
    // (status "reverify_required"), to prompt an online re-verification.
    GracePeriodWarningDialog {
        id: gracePeriodDialog
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
        // Don't interrupt a running session. Offline grace is silent: a paying
        // user keeps working undisturbed on the stored license details, and any
        // status change is enforced on the next startup instead of mid-session.
        if (appState === "main") {
            return
        }

        var status = appManager.licenseStatus
        console.log("License status:", status)

        // Offline grace exhausted: gate the app behind an online re-verification
        // (the license isn't expired, it just hasn't been checked in too long).
        if (status === "reverify_required") {
            if (!gracePeriodDialog.opened)
                gracePeriodDialog.open()
            return
        }
        // Any other state - make sure the re-verify dialog isn't left open.
        if (gracePeriodDialog.opened)
            gracePeriodDialog.close()

        if (status === "not_activated") {
            appState = "activation"
        } else if (status === "blocked") {
            // License genuinely invalid/expired -> blocked page to renew.
            appState = "blocked"
        } else if (appManager.isLicenseValid) {
            // Valid license: active, trial, OR quiet offline grace_period.
            // No warning dialog - go straight in.
            if (!appManager.hasAdminSetup) {
                appState = "setup"
            } else {
                appState = "login"
            }
        }
    }
}
