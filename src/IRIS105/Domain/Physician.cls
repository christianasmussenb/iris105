Class IRIS105.Domain.Physician Extends %RegisteredObject
{
}    Property LastName As %String(MAXLEN = 128);
    Property SpecialtyId As %String(MAXLEN = 64);
    Property DefaultBoxId As %String(MAXLEN = 64);
    Index PhysicianIdIndex On PhysicianId;
}