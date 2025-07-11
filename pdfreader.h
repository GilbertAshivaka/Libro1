#ifndef PDFREADER_H
#define PDFREADER_H

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QDir>
#include <QStandardPaths>

class PdfReader : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QStringList recentFiles READ recentFiles WRITE setRecentFiles NOTIFY recentFilesChanged)
    Q_PROPERTY(QString lastOpenedPath READ lastOpenedPath WRITE setLastOpenedPath NOTIFY lastOpenedPathChanged)

public:
    explicit PdfReader(QObject *parent = nullptr);

    QStringList recentFiles() const;
    void setRecentFiles(const QStringList &files);

    QString lastOpenedPath() const;
    void setLastOpenedPath(const QString &path);

public slots:
    Q_INVOKABLE void addRecentFile(const QString &filePath);
    Q_INVOKABLE void clearRecentFiles();
    Q_INVOKABLE QString getDocumentsPath();
    Q_INVOKABLE bool fileExists(const QString &filePath);
    Q_INVOKABLE QString getFileName(const QString &filePath);
    Q_INVOKABLE QString getFileDirectory(const QString &filePath);

signals:
    void recentFilesChanged();
    void lastOpenedPathChanged();

private:
    QStringList m_recentFiles;
    QString m_lastOpenedPath;
    static const int MAX_RECENT_FILES = 10;

    void saveSettings();
    void loadSettings();
    QString formatFilePath(const QString &filePath);
};

#endif // PDFREADER_H
