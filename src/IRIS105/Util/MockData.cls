Class IRIS105.Util.MockData Extends %RegisteredObject
{
}        // Método esqueleto: implementar generación y persistencia de datos
        If $Data(pConfig)=0 {
            Set pConfig = ..GetDefaultConfig()
        }
        Quit $$$OK
    }

    ClassMethod GetDefaultConfig()
    {
        Quit ##class(IRIS105.Util.MockConfig).GetDefault()
    }
}