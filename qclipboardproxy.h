#ifndef CLIPBOARDPROXY_HPP
#define CLIPBOARDPROXY_HPP

#include <QObject>
#include <QClipboard>

class ClipboardProxy : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString text READ dataText WRITE setDataText NOTIFY dataChanged)
    Q_PROPERTY(QString selectionText READ selectionText WRITE setSelectionText NOTIFY selectionChanged)
public:
    explicit ClipboardProxy(QObject *parent = 0);

    void setDataText(const QString &text);
    QString dataText() const;

    void setSelectionText(const QString &text);
    QString selectionText() const;

signals:
    void dataChanged();
    void selectionChanged();
};

#endif // CLIPBOARDPROXY_HPP