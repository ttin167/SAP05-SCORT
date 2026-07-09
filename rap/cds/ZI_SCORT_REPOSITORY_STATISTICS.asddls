@EndUserText.label: 'SCORT Repository Statistics'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_SCORT_STATISTICS_QUERY'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Statistic',
  typeNamePlural: 'Statistics',
  title: { value: 'GroupLabel' },
  description: { value: 'Dimension' }
}
define root custom entity ZI_SCORT_REPOSITORY_STATISTICS
{
      @EndUserText.label: 'Dimension'
      @UI.lineItem: [{ position: 5 }]
      @UI.selectionField: [{ position: 10 }]
  key Dimension   : abap.char(10);

      @EndUserText.label: 'Group Key'
      @UI.lineItem: [{ position: 10 }]
  key GroupKey    : abap.char(30);

      @EndUserText.label: 'Group Label'
      @UI.lineItem: [{ position: 20 }]
      GroupLabel  : abap.char(40);

      @EndUserText.label: 'Object Count'
      @UI.lineItem: [{ position: 30 }]
      ObjectCount : abap.int4;
}
