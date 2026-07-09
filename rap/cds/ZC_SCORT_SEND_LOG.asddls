@EndUserText.label: 'SCORT Send Log (UI)'
@Metadata.allowExtensions: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI.headerInfo: {
  typeName: 'Send Log',
  typeNamePlural: 'Send Log',
  title: { value: 'DevClass' },
  description: { value: 'StatusText' }
}
define root view entity ZC_SCORT_SEND_LOG
  provider contract transactional_query
  as projection on ZI_SCORT_SEND_LOG
{
      @UI.lineItem: [{ position: 10 }]
      @UI.identification: [{ position: 10 }]
  key SendGuid,

      @EndUserText.label: 'Package'
      @UI.lineItem: [{ position: 20 }]
      @UI.selectionField: [{ position: 10 }]
      DevClass,

      @EndUserText.label: 'Target System'
      @UI.lineItem: [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      TargetSystem,

      @EndUserText.label: 'Status'
      @UI.lineItem: [{ position: 40 }]
      @UI.selectionField: [{ position: 30 }]
      Status,

      @EndUserText.label: 'Status (display)'
      @UI.lineItem: [{ position: 50 }]
      StatusText,

      @EndUserText.label: 'Object Count'
      @UI.lineItem: [{ position: 60 }]
      ObjectCount,

      @EndUserText.label: 'Sent By'
      @UI.lineItem: [{ position: 70 }]
      SendBy,

      @EndUserText.label: 'Sent At'
      @UI.lineItem: [{ position: 80 }]
      SendTimestamp,

      @EndUserText.label: 'Message'
      @UI.lineItem: [{ position: 90 }]
      Message
}
