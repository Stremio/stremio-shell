#ifndef RAZERCHROMA_H
#define RAZERCHROMA_H

#include <QtCore/QObject>

#ifdef _WIN32
#include "chroma.h"
#endif

class RazerChroma : public QObject
{
    Q_OBJECT
public:
public slots:
    void enable();
    void disable();
private: 
#ifdef _WIN32
    CChromaSDKImpl *m_ChromaSDKImpl = NULL;
#endif
};

#endif // RAZERCHROMA_H
