Class IRIS105.Patient Extends %Persistent
{
    Property PatientId As %String(MAXLEN = 64);
    Property Run As %String(MAXLEN = 64);
    Property FirstName As %String(MAXLEN = 128);
    Property LastName As %String(MAXLEN = 128);
    Property Sex As %String(MAXLEN = 1);
    Property BirthDate As %Date;
    Property PayerId As %String(MAXLEN = 64);
    Property Region As %String(MAXLEN = 128);
    Property SocioEconomicSegment As %String(MAXLEN = 8);
    Index PatientIdIndex On PatientId;
}