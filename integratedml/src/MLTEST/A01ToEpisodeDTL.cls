Class MLTEST.A01ToEpisodeDTL Extends Ens.DataTransformDTL [ DependsOn = (EnsLib.HL7.Message, MLTEST.Data.Episode) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='EnsLib.HL7.Message' targetClass='MLTEST.Data.Episode' sourceDocType='2.5.1:ADT_A01' create='new' language='objectscript' >
<assign value='..Lookup("Hospital",source.{MSH:SendingFacility.NamespaceID})' property='target.Hospital' action='set' />
<assign value='..Lookup("Province",..Lookup("HospitalProvince",source.{MSH:SendingFacility.NamespaceID}))' property='target.Province' action='set' />
<assign value='##class("%Library.UTC").ConvertHorologToTimeStamp($ZDATETIMEH($EXTRACT(source.{PV1:AdmitDateTime},1,8)_" "_$EXTRACT(source.{PV1:AdmitDateTime},9,10)_":"_$EXTRACT(source.{PV1:AdmitDateTime},11,12)_":"_$EXTRACT(source.{PV1:AdmitDateTime},13,14),15,1))' property='target.AdmissionDate' action='set' />
<assign value='$ZD($H,8)-$ZD($ZDH(source.GetValueAt("PID:DateTimeofBirth.Time"),8),8)\10000' property='target.Age' action='set' />
<assign value='..Lookup("SexHL7",source.{PID:AdministrativeSex})' property='target.Sex' action='set' />
<assign value='$SYSTEM.SQL.Functions.DAYOFWEEK(##class("%Library.UTC").ConvertHorologToTimeStamp($ZDATETIMEH($EXTRACT(source.{PV1:AdmitDateTime},1,8)_" "_$EXTRACT(source.{PV1:AdmitDateTime},9,10)_":"_$EXTRACT(source.{PV1:AdmitDateTime},11,12)_":"_$EXTRACT(source.{PV1:AdmitDateTime},13,14),15,1)))' property='target.AdmissionWeekDay' action='set' />
</transform>
}

}
