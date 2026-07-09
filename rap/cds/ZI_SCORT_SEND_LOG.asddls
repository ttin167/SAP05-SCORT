@EndUserText.label: 'SCORT Send Log'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_SCORT_SEND_LOG
  as select from zscort_send_log
{
  key send_guid       as SendGuid,
      devclass        as DevClass,
      target_system     as TargetSystem,
      send_by         as SendBy,
      send_timestamp  as SendTimestamp,
      status          as Status,
      status_text     as StatusText,
      object_count    as ObjectCount,
      message         as Message
}
