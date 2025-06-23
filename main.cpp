#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtWidgets/QApplication>
#include <QQuickStyle>
#include <QQmlContext>

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


#include "issuebookslist.h"// for issuing books
#include "issuebookslistmodel.h"

#include "issuedbookslist.h"
#include "issuedbookslistmodel.h"

#include "backupmanager.h"

//for the barcode
#include "barcodereader.h"
#include "barcodewriter.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQuickStyle::setStyle("Material");
    DatabaseManager dbManager;
    if (!dbManager.isdbInitialized()){
        qDebug() << "Database initialisation failed.";
        return -1;
    }

    qDebug() << "Database initialised successfully.";

    qmlRegisterType<DatabaseManager>("com.databaseManager", 1, 0, "DatabaseManager");
    qmlRegisterType<UserManager>("UserManager", 1, 0, "UserManager");
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

    qmlRegisterType<BackupManager>("com.backupManager", 1, 0, "BackupManager");


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

    // registering the allbookslist class
    AllBooksList allBooksList;
    AllUsersList allUsersList;
    IssueBooksList issueBooksList;
    IssuedBooksList issuedBooksList;


    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(QStringLiteral("allBooksList"), &allBooksList);
    engine.rootContext()->setContextProperty(QStringLiteral("allUsersList"), &allUsersList);
    engine.rootContext()->setContextProperty(QStringLiteral("issueBooksList"), &issueBooksList);
    engine.rootContext()->setContextProperty(QStringLiteral("issuedBooksList"), &issuedBooksList);


    const QUrl url(u"qrc:/Libro1/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
