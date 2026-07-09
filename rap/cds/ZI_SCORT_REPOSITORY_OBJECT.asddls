@EndUserText.label: 'SCORT Repository Object'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SCORT_OBJECT_QUERY'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Repository Object',
  typeNamePlural: 'Repository Objects',
  title: { value: 'ObjectName' },
  description: { value: 'ObjectType' }
}

define root custom entity ZI_SCORT_REPOSITORY_OBJECT
{
 @UI.facet: [
    {
      id: 'GeneralInfo',
      purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: 'General Information',
      position: 10
    }
  ]

  @EndUserText.label: 'Object Type'
  @UI.lineItem: [{ position: 10 }]
  @UI.selectionField: [{ position: 20 }]
  @UI.identification: [{ position: 10 }]
  key ObjectType  : abap.char(4);

  @EndUserText.label: 'Object Name'
  @UI.lineItem: [{ position: 20 }]
  @UI.selectionField: [{ position: 10 }]
  @UI.identification: [{ position: 20 }]
  key ObjectName  : abap.char(120);

  @EndUserText.label: 'Package'
  @UI.lineItem: [{ position: 30 }]
  @UI.selectionField: [{ position: 30 }]
  @UI.identification: [{ position: 30 }]
      DevClass    : abap.char(30);

  @EndUserText.label: 'Author'
  @UI.lineItem: [{ position: 40 }]
  @UI.selectionField: [{ position: 40 }]
  @UI.identification: [{ position: 40 }]
      Author      : abap.char(12);

  @EndUserText.label: 'Created By'
  @UI.identification: [{ position: 50 }]
      CreatedBy   : abap.char(12);

  @EndUserText.label: 'Created On'
  @UI.identification: [{ position: 60 }]
      CreatedDate : abap.dats;

  @EndUserText.label: 'Changed On'
  @UI.identification: [{ position: 70 }]
      ChangedDate : abap.dats;
}
