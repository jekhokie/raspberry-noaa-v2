CONFIG += c++14 console
CONFIG -= app_bundle

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS LIQUID_BUILD_CPLUSPLUS
DEFINES +=_USE_MATH_DEFINES

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    GIS/dbfilereader.cpp \
    decoder/deinterleaver.cpp \
    decoder/viterbi.cpp \
    main.cpp \
    GIS/shapereader.cpp \
    GIS/shaperenderer.cpp \
    decoder/meteorimage.cpp \
    decoder/packetparser.cpp \
    decoder/reedsolomon.cpp \
    decoder/bitio.cpp \
    decoder/correlation.cpp \
    imageproc/spreadimage.cpp \
    imageproc/threatimage.cpp \
    common/settings.cpp \
    tools/databuffer.cpp \
    tools/iniparser.cpp \
    tools/pixelgeolocationcalculator.cpp \
    tools/tlereader.cpp \
    tools/matrix.cpp \
    tools/vector.cpp \
    tools/databuffer.cpp \
    DSP/agc.cpp \
    DSP/pll.cpp \
    DSP/filter.cpp \
    DSP/iqsource.cpp \
    DSP/meteordemodulator.cpp \
    DSP/wavreader.cpp


# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    GIS/dbfilereader.h \
    GIS/shapereader.h \
    GIS/shaperenderer.h \
    decoder/deinterleaver.h \
    decoder/viterbi.h \
    decoder/meteorimage.h \
    decoder/packetparser.h \
    decoder/bitio.h \
    decoder/correlation.h \
    decoder/reedsolomon.h \
    imageproc/spreadimage.h \
    imageproc/threatimage.h \
    common/settings.h \
    common/version.h \
    tools/databuffer.h \
    tools/iniparser.h \
    tools/pixelgeolocationcalculator.h \
    tools/matrix.h \
    tools/tlereader.h \
    tools/vector.h \
    tools/databuffer.h \
    DSP/agc.h \
    DSP/pll.h \
    DSP/filter.h \
    DSP/iqsource.h \
    DSP/meteordemodulator.h \
    DSP/wavreader.h

INCLUDEPATH +=  ../../opencv/own_build/install/include
INCLUDEPATH +=  ./decoder
INCLUDEPATH +=  ./common
INCLUDEPATH +=  ./tools
INCLUDEPATH +=  ./imageproc
INCLUDEPATH +=  $$PWD/external/libcorrect/include
INCLUDEPATH +=  $$PWD/external/sgp4/libsgp4

win32 {
    CONFIG(debug, debug|release) {
        LIBS += $$PWD/external/libcorrect/build/lib/Debug/correct.lib
        LIBS += $$PWD/external/sgp4/build/libsgp4/Debug/sgp4.lib

        LIBS += -L$$PWD/../../opencv/own_build/lib/Debug
        SHARED_LIB_FILES = $$files($$PWD/../../opencv/own_build/lib/Debug/*.lib)
        for(FILE, SHARED_LIB_FILES) {
            BASENAME = $$basename(FILE)
            LIBS += -l$$replace(BASENAME,\.lib,)
        }
    } else {
        LIBS += $$PWD/external/libcorrect/build/lib/Release/correct.lib
        LIBS += $$PWD/external/sgp4/build/libsgp4/Release/sgp4.lib

        LIBS += -L$$PWD/../../opencv/own_build/lib/Release
        SHARED_LIB_FILES = $$files($$PWD/../../opencv/own_build/lib/Release/*.lib)
        for(FILE, SHARED_LIB_FILES) {
            BASENAME = $$basename(FILE)
            LIBS += -l$$replace(BASENAME,\.lib,)
        }
    }
}


