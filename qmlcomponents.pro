TEMPLATE = subdirs
CONFIG += sailfishapp_qml

DISTFILES = \
    helpers/Dates.qml \
    models/SortedModel.qml \
    requester/Requester.qml \
    requester/requester.js \
    storage/Storage.qml \
    qmldir

helpers.files = helpers
#helpers.path = $${DEPLOYMENT_PATH}
models.files = models
requester.files = requester
storage.files = storage

RESOURCES = helpers + models + requester + storage + qmldir

#OTHER_FILES = qmldir
#qmldir.files += $$_PRO_FILE_PWD_/qmldir
#qmldir.path += $$target.path
#INSTALLS += qmldir
