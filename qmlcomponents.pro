#TEMPLATE = subdirs
CONFIG += sailfishapp_qml

DISTFILES = \
    helpers/Dates.qml \
    ui/DraggableItem.qml \
    requester/Requester.qml \
    requester/requester.js \
    models/SortedModel.qml \
    storage/Storage.qml \
    qmldir

helpers.files = helpers
#helpers.path = $${DEPLOYMENT_PATH}
models.files = models
requester.files = requester
storage.files = storage

RESOURCES = helpers models requester storage

#OTHER_FILES = qmldir
#qmldir.files += $$_PRO_FILE_PWD_/qmldir
#qmldir.path += $$target.path
#INSTALLS += qmldir
