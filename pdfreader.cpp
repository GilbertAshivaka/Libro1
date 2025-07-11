#include "pdfreader.h"
#include <QSettings>
#include <QFileInfo>
#include <QUrl>
#include <QDebug>

PdfReader::PdfReader(QObject *parent)
    : QObject(parent)
{
    loadSettings();
}

QStringList PdfReader::recentFiles() const
{
    return m_recentFiles;
}

void PdfReader::setRecentFiles(const QStringList &files)
{
    if (m_recentFiles != files) {
        m_recentFiles = files;
        emit recentFilesChanged();
        saveSettings();
    }
}

QString PdfReader::lastOpenedPath() const
{
    return m_lastOpenedPath;
}

void PdfReader::setLastOpenedPath(const QString &path)
{
    if (m_lastOpenedPath != path) {
        m_lastOpenedPath = path;
        emit lastOpenedPathChanged();
        saveSettings();
    }
}

void PdfReader::addRecentFile(const QString &filePath)
{
    if (filePath.isEmpty() || !fileExists(filePath)) {
        return;
    }

    QString cleanPath = formatFilePath(filePath);

    // Remove the file if it already exists in the list
    m_recentFiles.removeAll(cleanPath);

    // Add to the beginning of the list
    m_recentFiles.prepend(cleanPath);

    // Keep only the maximum number of recent files
    while (m_recentFiles.size() > MAX_RECENT_FILES) {
        m_recentFiles.removeLast();
    }

    // Update last opened path to the directory of this file
    QFileInfo fileInfo(cleanPath);
    setLastOpenedPath(fileInfo.absolutePath());

    emit recentFilesChanged();
    saveSettings();
}

void PdfReader::clearRecentFiles()
{
    if (!m_recentFiles.isEmpty()) {
        m_recentFiles.clear();
        emit recentFilesChanged();
        saveSettings();
    }
}

QString PdfReader::getDocumentsPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
}

bool PdfReader::fileExists(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return false;
    }

    QString cleanPath = formatFilePath(filePath);
    QFileInfo fileInfo(cleanPath);
    return fileInfo.exists() && fileInfo.isFile();
}

QString PdfReader::getFileName(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return QString();
    }

    QString cleanPath = formatFilePath(filePath);
    QFileInfo fileInfo(cleanPath);
    return fileInfo.fileName();
}

QString PdfReader::getFileDirectory(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return QString();
    }

    QString cleanPath = formatFilePath(filePath);
    QFileInfo fileInfo(cleanPath);
    return fileInfo.absolutePath();
}

void PdfReader::saveSettings()
{
    QSettings settings("ILMS", "PdfReader");
    settings.beginGroup("RecentFiles");
    settings.setValue("files", m_recentFiles);
    settings.setValue("lastPath", m_lastOpenedPath);
    settings.endGroup();
}

void PdfReader::loadSettings()
{
    QSettings settings("ILMS", "PdfReader");
    settings.beginGroup("RecentFiles");

    QStringList files = settings.value("files").toStringList();

    // Filter out files that no longer exist
    QStringList validFiles;
    for (const QString &file : files) {
        if (fileExists(file)) {
            validFiles.append(file);
        }
    }

    m_recentFiles = validFiles;
    m_lastOpenedPath = settings.value("lastPath", getDocumentsPath()).toString();

    settings.endGroup();
}

QString PdfReader::formatFilePath(const QString &filePath)
{
    // Handle file:// URLs
    if (filePath.startsWith("file://")) {
        QUrl url(filePath);
        return url.toLocalFile();
    }

    return filePath;
}
