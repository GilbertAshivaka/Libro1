#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtWidgets/QApplication>
#include <QQuickStyle>
#include <QQmlContext>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#include "databasemanager.h"
#include "usermanager.h"
#include "bookmanager.h"
#include "allbookslistmodel.h"
#include "allbookslist.h"
#include "userimporter.h"
#include "alluserslist.h"
#include "alluserslistmodel.h"
#include "bookimporter.h"
#include "categorylist.h" //for the class to populate a model for the categories of the books
#include "singlebookreturn.h"
#include "inventorymanager.h"
#include "emailnotificationcontroller.h"
#include "opacmanager.h"
#include "reportsmanager.h"
#include "reportexporter.h"
#include "settingsmanager.h"
#include "analyticsmanager.h"
#include "clearancemanager.h"
#include "reservationmanager.h"
#include "suggestionsmanager.h"
#include "usermanager.h"
#include "loginmanager.h"

#include "appmanager.h"
#include "barcodewriter.h"


#include "issuebookslist.h"// for issuing books
#include "issuebookslistmodel.h"

#include "issuedbookslist.h"
#include "issuedbookslistmodel.h"

#include "backupmanager.h"
#include "activitylogs.h"
#include "bookshopmanager.h"
#include "storagemanager.h"
#include "digitalmaterialsmanager.h"

//for the barcode
#include "barcodereader.h"
#include "barcodewriter.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    QtWebEngineQuick::initialize(); //initialize the webEngine before creating the application

    QApplication app(argc, argv);

    app.setOrganizationName("Libro");
    app.setOrganizationDomain("libroILMS.com");
    app.setApplicationName("LIbroILMS");

    QQuickStyle::setStyle("Material");
    DatabaseManager dbManager;
    if (!dbManager.isdbInitialized()){
        qDebug() << "Database initialisation failed.";
        return -1;
    }

    qDebug() << "Database initialised successfully.";

    qmlRegisterType<DatabaseManager>("com.databaseManager", 1, 0, "DatabaseManager");
    // qmlRegisterType<UserManager>("UserManager", 1, 0, "UserManager"); //functionality transfered to userManager singleton
    qmlRegisterType<BookManager>("com.bookmanager", 1, 0, "BookManager");
    qmlRegisterType<AllBooksListModel>("com.allbookslistmodel", 1, 0, "AllBooksListModel");
    qmlRegisterType<UserImporter>("com.userImporter", 1, 0, "UserImporter");
    qmlRegisterType<AllUsersListModel>("com.allUsersListModel", 1, 0, "AllUsersListModel");
    qmlRegisterType<BookImporter>("com.bookImporter", 1, 0, "BookImporter");
    qmlRegisterType<CategoryList>("com.categorylist", 1, 0, "CategoryList");

    qmlRegisterType<IssueBooksListModel>("com.issueBooksListModel", 1, 0, "IssueBooksListModel");
    qmlRegisterType<IssuedBooksListModel>("com.issuedBooksListModel", 1, 0, "IssuedBooksListModel");

    qmlRegisterType<SingleBookReturn>("com.singleBookReturn", 1, 0, "SingleBookReturn");
    qmlRegisterType<InventoryManager>("com.inventoryManager", 1, 0, "InventoryManager");

    // qmlRegisterType<BackupManager>("com.backupManager", 1, 0, "BackupManager");
    qmlRegisterType<BookshopManager>("com.bookshopManager", 1, 0, "BookshopManager");
    qmlRegisterType<StorageManager>("com.storageManager", 1, 0, "StorageManager");
    qmlRegisterType<DigitalMaterialsManager>("com.digitalMaterialsManager", 1, 0, "DigitalMaterialsManager");
    qmlRegisterType<ClearanceManager>("com.clearanceManager", 1, 0, "ClearanceManager");
    qmlRegisterType<ReservationManager>("com.reservationManager", 1, 0, "ReservationManager");


    qmlRegisterUncreatableType<AllBooksList>("AllBooksList", 1, 0, "AllBooksList",
                                             QStringLiteral("AllBooksList should not be created in QML"));
    qmlRegisterUncreatableType<AllUsersList>("AllUsersList", 1, 0, "AllUsersList",
                                             QStringLiteral("AllUsersList should not be created in QML"));
    qmlRegisterUncreatableType<IssueBooksList>("IssueBooksList", 1, 0, "IssueBooksList",
                                               QStringLiteral("IssueBooksList should not be created in QML"));

    qmlRegisterUncreatableType<IssuedBooksList>("IssuedBooksList", 1, 0, "IssuedBooksList",
                                                QStringLiteral("IssuedBooksList should not be created in QML"));

    //for th barcode
    qmlRegisterType<ZXingQt::BarcodeReader>("ZXing", 1, 0, "BarcodeReader");
    qmlRegisterType<BarcodeWriter>("WriteBarcode", 1, 0, "WriteBarcode");


    // Create AppManager singleton FIRST (it needs to be ready for license check)
    AppManager *appManager = AppManager::instance();

    // registering the allbookslist class
    AllBooksList allBooksList;
    AllUsersList allUsersList;
    IssueBooksList issueBooksList;
    IssuedBooksList issuedBooksList;

    ActivityLogs activityLogsClass;
    EmailNotificationController emailNotificationController; //for email notifications
    OpacManager opacManager;
    ReportsManager reportsManager;
    ReportExporter reportExporter;
    BackupManager backupManagerInstance;
    AnalyticsManager analyticsManager;

    SuggestionsManager *suggestionsManager = new SuggestionsManager();
    LoginManager *loginManager = new LoginManager();
    UserManager *userManager = new UserManager();



    QQmlApplicationEngine engine;

    // Register as context property so QML can access it
    engine.rootContext()->setContextProperty("appManager", appManager);

    engine.rootContext()->setContextProperty(QStringLiteral("allBooksList"), &allBooksList);
    engine.rootContext()->setContextProperty(QStringLiteral("allUsersList"), &allUsersList);
    engine.rootContext()->setContextProperty(QStringLiteral("issueBooksList"), &issueBooksList);
    engine.rootContext()->setContextProperty(QStringLiteral("issuedBooksList"), &issuedBooksList);
    engine.rootContext()->setContextProperty(QStringLiteral("activityLogsClass"), &activityLogsClass);
    engine.rootContext()->setContextProperty(QStringLiteral("emailNotificationController"), &emailNotificationController);
    engine.rootContext()->setContextProperty(QStringLiteral("opacManager"), &opacManager);
    engine.rootContext()->setContextProperty(QStringLiteral("reportsManager"), &reportsManager);
    engine.rootContext()->setContextProperty(QStringLiteral("reportExporter"), &reportExporter);
    engine.rootContext()->setContextProperty("analyticsManager", &analyticsManager);

    engine.rootContext()->setContextProperty("suggestionsManager", suggestionsManager);
    engine.rootContext()->setContextProperty("loginManager", loginManager);
    engine.rootContext()->setContextProperty("userManager", userManager);

    engine.rootContext()->setContextProperty("barcodeWriter", BarcodeWriter::instance());


    //Register BackupManager as QML singleton.
    qmlRegisterSingletonType<BackupManager>(
        "com.backupManager", 1, 0, "BackupManagerInstance",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            static BackupManager* instance = new BackupManager();
            return instance;
        });


    // Register SettingsManager as a QML singleton
    qmlRegisterSingletonType<SettingsManager>(
        "com.libro.settings", 1, 0, "SettingsManager",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return SettingsManager::instance();
        }
        );

    const QUrl url(u"qrc:/Libro1/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
