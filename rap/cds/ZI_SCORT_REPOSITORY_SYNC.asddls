@EndUserText.label: 'SCORT Repository Sync Matrix'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SCORT_SYNC_QUERY'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Sync Entry',
  typeNamePlural: 'Sync Matrix',
  title: { value: 'ObjectName' },
  description: { value: 'SyncStatusText' }
}
define root custom entity ZI_SCORT_REPOSITORY_SYNC
{
  @EndUserText.label: 'Object Type'
  @UI.lineItem: [
    { position: 10 },
    { type: #FOR_ACTION, dataAction: 'sendPackage', label: 'Send to S35', position: 90 }
  ]
  @UI.selectionField: [{ position: 20 }]
  key ObjectType      : abap.char(4);

  @EndUserText.label: 'Object Name'
  @UI.lineItem: [{ position: 20 }]
  @UI.selectionField: [{ position: 10 }]
  key ObjectName      : abap.char(120);

  @EndUserText.label: 'Package'
  @UI.lineItem: [{ position: 30 }]
  @UI.selectionField: [{ position: 30 }]
      DevClass        : abap.char(30);

  @EndUserText.label: 'Author'
  @UI.lineItem: [{ position: 40 }]
  @UI.selectionField: [{ position: 40 }]
      Author          : abap.char(12);

  @EndUserText.label: 'Sync Status'
  @UI.lineItem: [{ position: 50 }]
  @UI.selectionField: [{ position: 50 }]
      SyncStatus      : abap.char(20);

  @EndUserText.label: 'Sync Status (display)'
  @UI.lineItem: [{ position: 60 }]
      SyncStatusText  : abap.char(40);
}
