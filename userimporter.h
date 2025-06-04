#ifndef USERIMPORTER_H
#define USERIMPORTER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QFile>
#include <QTextStream>
#include <QFutureWatcher>
#include <functional>
#include <QSqlDatabase>

struct ImportResult {
    int successCount;
    int failCount;
    QStringList errors;

    ImportResult(int success = 0, int fail = 0, const QStringList &errs = QStringList())
        : successCount(success), failCount(fail), errors(errs) {}
};

class UserImporter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString userRole READ userRole WRITE setUserRole NOTIFY userRoleChanged)

public:
    explicit UserImporter(QObject *parent = nullptr);
    ~UserImporter();

    QString userRole();
    void setUserRole(QString &newUserRole);
    Q_INVOKABLE void startImport(const QString &filePath);
    Q_INVOKABLE QString urlToLocalFile(const QString &url);
    Q_INVOKABLE void setRole(QString role);

signals:
    void importProgress(int progress);
    void importCompleted(int successCount, int failCount);
    void importError(const QString &error);
    void userRoleChanged();

private slots:
    void handleImportCompleted();

private:
    QString m_userRole;
    QFutureWatcher<ImportResult> *watcher;

    ImportResult processImport(const QString &filePath, const std::function<void(int)> &progressCallback);
    bool validateUserData(const QStringList &userData);
    bool processUserRecord(QSqlDatabase &db, const QStringList &userData);
    QString detectUserType(const QStringList& headers);
    bool validateUserTypeMatch(const QString& detectedType, const QString& selectedRole);
    void parseHeaders(const QString& headerLine, QStringList& headers);
};

#endif // USERIMPORTER_H
